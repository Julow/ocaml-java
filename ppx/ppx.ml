open Ast_mapper
open Ast_helper
open Parsetree
open Asttypes
open Longident

(* - *)

let module_name = String.capitalize_ascii

let java_class_fmt = String.map (function '.' -> '/' | c -> c)

let arg_name = Printf.sprintf "x%d"

(* - *)

(* Names of classes saw until now *)
let known_classes = Hashtbl.create 10

let add_known_class (name, jname, _) =
    Hashtbl.add known_classes name jname

(* AST Helpers *)

let mk_loc txt = { txt; loc = !default_loc }

let mk_ident =
	let rec ident acc =
		function
		| l :: r	-> ident (Ldot (acc, l)) r
		| []		-> acc
	in
	function
	| l :: r	-> Exp.ident (mk_loc (ident (Lident l) r))
	| []		-> assert false

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
	| [%type: unit] as t			->
		let push_func _ = Location.raise_errorf ~loc:t.ptyp_loc
			"unit can only be a return type"
		and call_func arg = mk_call_dot_s ("Java", "call_void") [ "obj"; arg ] in
		{ sigt = "V"; push_func; call_func }

	| [%type: int]					-> t "I" "int"
	| [%type: bool]					-> t "Z" "bool"
	| [%type: byte]					-> t "B" "byte"
	| [%type: short]				-> t "S" "short"
	| [%type: int32]				-> t "I" "int32"
	| [%type: long]					-> t "J" "long"
	| [%type: char]					-> t "C" "char"
	| [%type: float]				-> t "F" "float"
	| [%type: double]				-> t "D" "double"
	| [%type: string]				-> t "Ljava/lang/String;" "string"
	| [%type: string option]		-> t "Ljava/lang/String;" "string_opt"
	| [%type: [%t? _] value]		-> t "Ljuloo/javacaml/Value;" "value"
	| [%type: [%t? _] value option]	-> t "Ljuloo/javacaml/Value;" "value_opt"
	| [%type: Java.obj]				-> t "Ljava/lang/Object;" "object"

	| [%type: [%t? { ptyp_desc = Ptyp_constr ({ txt = Lident name }, []) }]]
			when Hashtbl.mem known_classes name ->
		let cn = java_class_fmt (Hashtbl.find known_classes name) in
		let mn = module_name name in

		let push_func arg =
			let arg = mk_ident [ arg ]
			and to_obj = mk_ident [ mn; "to_obj" ] in
			[%expr Java.push_object ([%e to_obj] [%e arg])]

		and call_func arg =
			[%expr let r = Java.call_object obj [%e mk_ident [ arg ]] in
				if r == Java.null then failwith "null obj"
				else [%e mk_ident [ mn; "of_obj_unsafe" ]] r]
		in

		{ sigt = "L" ^ cn ^ ";"; push_func; call_func }

	| { ptyp_loc = loc } -> Location.raise_errorf ~loc "Unsupported type"

let rec unwrap_method_type =
	function
	| [%type: [%t? lhs] -> [%t? rhs]]	->
		let args, ret = match rhs with
			| [%type: [%t? _] -> [%t? _]]	-> unwrap_method_type rhs
			| _								-> [], unwrap_core_type rhs
		in
		unwrap_core_type lhs :: args, ret
	| t								-> [], unwrap_core_type t

let unwrap_class_field =
	function
	| { pcf_desc = Pcf_method (_, _, Cfk_virtual _); pcf_loc = loc } ->
		Location.raise_errorf ~loc "Virtual method unsupported"
	| { pcf_desc = Pcf_method (_, _, Cfk_concrete (Override, _));
			pcf_loc = loc } ->
		Location.raise_errorf ~loc "Override method unsupported"
	| { pcf_desc = Pcf_method (_, Private, _); pcf_loc = loc } ->
		Location.raise_errorf ~loc "Private method unsupported"
	| { pcf_desc = Pcf_method ({ txt = name }, Public, Cfk_concrete (Fresh,
			{ pexp_desc = Pexp_poly (
				{ pexp_desc = Pexp_constant (Pconst_string (java_name, None)) },
				Some mtype
			) })) }	->
		`Method (name, java_name, lazy (unwrap_method_type mtype))
	| { pcf_desc = Pcf_method (_, _, Cfk_concrete (_, { pexp_desc =
			Pexp_poly ({ pexp_desc = _; pexp_loc = loc }, _) })) } ->
		Location.raise_errorf ~loc "Expecting Java method name"
	| { pcf_desc = Pcf_method (_, _, Cfk_concrete (_, { pexp_loc = loc })) } ->
		Location.raise_errorf ~loc "Expecting method signature"
	| { pcf_loc = loc } ->
		Location.raise_errorf ~loc "Unsupported"

(** Returns the tuple (class name, java class name, fields)
		where fields is
			[`Method (meth_name, java_name, lazy (args, ret types))]
		Oups: Types are `lazy` so that classes are added to `known_classes`
			before parsing them. errors may be raised later...
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
	| { pci_expr = { pcl_desc = Pcl_fun (_, _, _, { pcl_desc = Pcl_structure {
				pcstr_self = { ppat_desc; ppat_loc = loc }
			}})} } when ppat_desc <> Ppat_any ->
		Location.raise_errorf ~loc "self is not allowed"
	| { pci_expr = { pcl_desc = Pcl_fun (_, _, { ppat_desc =
			Ppat_constant (Pconst_string _) }, { pcl_loc = loc }) } } ->
		Location.raise_errorf ~loc "Expecting object"
	| { pci_loc = loc }		->
		Location.raise_errorf ~loc "Expecting Java class path"

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
		| `Method (name, jname, sigt)	->
			let args, ret as sigt = Lazy.force sigt in
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
		add_known_class cls;
		Str.module_ (gen_class cls)
	| item			-> default_mapper.structure_item mapper item

let mapper _ = { default_mapper with structure_item }

let () = register "ocaml-java-ppx" mapper
