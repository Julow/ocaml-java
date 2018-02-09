open Ast_mapper
open Ast_helper
open Parsetree
open Asttypes
open Longident

(* - *)

let module_name = String.capitalize_ascii

let java_class_fmt = String.map (function '.' -> '/' | c -> c)

let arg_name = Printf.sprintf "x%d"

(* AST Helpers *)

let mk_loc txt = { txt; loc = !default_loc }

let mk_call ident args = Exp.apply (Exp.ident (mk_loc ident)) args
let mk_call_dot (m, i) args =
	mk_call (Ldot (Lident m, i)) (List.map (fun arg -> Nolabel, arg) args)
let mk_call_dot_s ident args =
	let arg arg = Exp.ident (mk_loc (Lident arg)) in
	mk_call_dot ident (List.map arg args)

let rec mk_sequence =
	function
	| exp :: []	-> exp
	| exp :: tl	-> Exp.sequence exp (mk_sequence tl)
	| []		-> assert false

(* Type info *)

type type_info = {
	sigt : string;
	push_func : string -> expression;
	call_func : string -> expression
}

let jni_meth_sigt (args, ret) =
	String.concat "" @@
	"(" :: List.fold_right (fun t acc -> t.sigt :: acc) args [ ")"; ret.sigt ]

(* Unwrapper *)

let unwrap_core_type =
	let t sigt n =
		let push_func arg = mk_call_dot_s ("Java", "push_" ^ n) [ arg ]
		and call_func arg = mk_call_dot_s ("Java", "call_" ^ n) [ "obj"; arg ] in
		{ sigt; push_func; call_func }
	in

	function
	| Ptyp_constr ({ txt = Lident "int" }, [])		-> t "I" "int"
	| Ptyp_constr ({ txt = Lident "bool" }, [])		-> t "Z" "bool"
	| Ptyp_constr ({ txt = Lident "byte" }, [])		-> t "B" "byte"
	| Ptyp_constr ({ txt = Lident "short" }, [])	-> t "S" "short"
	| Ptyp_constr ({ txt = Lident "int32" }, [])	-> t "I" "int32"
	| Ptyp_constr ({ txt = Lident "long" }, [])		-> t "J" "long"
	| Ptyp_constr ({ txt = Lident "char" }, [])		-> t "C" "char"
	| Ptyp_constr ({ txt = Lident "float" }, [])	-> t "F" "float"
	| Ptyp_constr ({ txt = Lident "double" }, [])	-> t "D" "double"
	| Ptyp_constr ({ txt = Lident "string" }, [])	-> t "Ljava/lang/String;" "string"
	| Ptyp_constr ({ txt = Lident "option" }, [
		{ ptyp_desc = Ptyp_constr ({ txt = Lident "string" }, []) } ]) ->
		t "Ljava/lang/String;" "string_opt"
	| _							-> t "Ljuloo/javacaml/Value;" "value"

let rec unwrap_method_type =
	function
	| Ptyp_arrow (Nolabel, { ptyp_desc }, { ptyp_desc = Ptyp_arrow _ as rhs })	->
		let args, ret = unwrap_method_type rhs in
		unwrap_core_type ptyp_desc :: args, ret
	| Ptyp_arrow (Nolabel, { ptyp_desc = lhs }, { ptyp_desc = rhs })	->
		[ unwrap_core_type lhs ], unwrap_core_type rhs
	| t								-> [], unwrap_core_type t

let unwrap_class_field =
	function
	| { pcf_desc = Pcf_method ({ txt = name }, Public, Cfk_concrete (Fresh,
			{ pexp_desc = Pexp_poly (
				{ pexp_desc = Pexp_constant (Pconst_string (java_name, None)) },
				Some { ptyp_desc }
			) })) }	->
		`Method (name, java_name, unwrap_method_type ptyp_desc)
	| _ -> raise (Invalid_argument "unwrap_class_field")

(** Returns the tuple (class name, java class name, fields)
		where fields is `Method (meth_name, java_name, (arg types, ret type))
	Raises `Invalid_argument` if the class is not formatted correctly *)
let unwrap_class =
	function
	| {	pci_name = { txt = name };
		pci_expr = { pcl_desc = Pcl_fun (Nolabel, None,
				{ ppat_desc = Ppat_constant (Pconst_string (java_name, None)) },
				{ pcl_desc = Pcl_structure {
					pcstr_self = { ppat_desc = Ppat_any };
					pcstr_fields } }) } } ->
		(name, java_name, List.map unwrap_class_field pcstr_fields)
	| _ -> raise (Invalid_argument "unwrap_class")

(* Gen *)

let gen_func args body =
	List.fold_right (fun arg body ->
		Exp.fun_ Nolabel None (Pat.var (mk_loc arg)) body
	) args body

let gen_class (class_name, java_name, fields) =
	let globals, add_global =
		let globals, count = ref [], ref 0 in
		globals, fun g ->
			let id = Printf.sprintf "__%d" !count in
			incr count;
			globals := (id, g) :: !globals;
			id
	in

	(* Methods *)
	let items = List.fold_right (fun field items ->
		match field with
		| `Method (name, jname, (args, ret as sigt))	->
			let mid = add_global (`Method (jname, sigt)) in
			[%stri let [%p Pat.var (mk_loc name)] =
				[%e (gen_func ("obj" :: List.mapi (fun i _ -> arg_name i) args) (
					mk_sequence (
						List.mapi (fun i ti -> ti.push_func (arg_name i)) args
						@ [ ret.call_func mid ])
				))]] :: items
	) fields [] in

	(* Globals *)
	let items = List.fold_left (fun items ->
		function
		| id, `Method (name, sigt)		->
			[%stri let [%p Pat.var (mk_loc id)] = Jclass.get_meth __cls
					[%e Exp.constant (Const.string name)]
					[%e Exp.constant (Const.string (jni_meth_sigt sigt))]]
			:: items
	) items !globals in

	(* Pervasives *)
	let items = [
		[%stri type t];

		[%stri let __cls = Jclass.find_class
			[%e Exp.constant (Const.string (java_class_fmt java_name))]];

		[%stri external to_obj : t -> Java.obj = "%identity"];

		[%stri external of_obj_unsafe : Java.obj -> t = "%identity"];

		[%stri let of_obj obj =
			if Java.instanceof obj __cls
			then of_obj_unsafe obj
			else failwith "of_obj"]

	] @ items in

	let mn = module_name class_name in
	Mb.mk (mk_loc mn) (Mod.structure items)

(* Mapper *)

let structure_item mapper =
	function
	| { pstr_desc = Pstr_extension (({ txt = "java" }, PStr [
			{ pstr_desc = Pstr_class [ cls ] }
		]), _) }	->
		let cls = unwrap_class cls in
		Str.module_ (gen_class cls)
	| item			-> item

let mapper _ = { default_mapper with structure_item }

let () = register "ocaml-java-ppx" mapper
