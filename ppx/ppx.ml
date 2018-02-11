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

(* The variable `obj` is expected to be defined,
	`write_field` expects the variable `v` to be defined
	`call_static` expects `__cls` *)
type type_info = {
	sigt : string;
	push : string -> expression;
	call : string -> expression;
	call_static : string -> expression;
	read_field : string -> expression;
	write_field : string -> expression;
	read_field_static : string -> expression;
	write_field_static : string -> expression
}

let concat_sigt args =
	String.concat "" @@
	List.map (fun t -> t.sigt) args

let jni_meth_sigt (args, ret) =
	Printf.sprintf "(%s)%s" (concat_sigt args) ret.sigt

(* Unwrapper *)

let unwrap_core_type =
	let t sigt n =
		let push arg = mk_call_dot_s ("Java", "push_" ^ n) [ arg ]
		and call mid = mk_call_dot_s ("Java", "call_" ^ n) [ "obj"; mid ]
		and call_static mid =
			mk_call_dot_s ("Java", "call_static_" ^ n) [ "__cls"; mid ]
		and read_field fid =
			mk_call_dot_s ("Java", "read_field_" ^ n) [ "obj"; fid ]
		and write_field fid =
			mk_call_dot_s ("Java", "write_field_" ^ n) [ "obj"; fid; "v" ]
		and read_field_static fid =
			mk_call_dot_s ("Java", "read_field_static_" ^ n) [ "__cls"; fid ]
		and write_field_static fid =
			mk_call_dot_s ("Java", "write_field_static_" ^ n) [ "__cls"; fid; "v" ]
		in
		{ sigt; push; call; call_static; read_field; write_field;
			read_field_static; write_field_static }
	in

	let t_class name conv_to conv_of =
		let cn = java_class_fmt (Hashtbl.find known_classes name) in
		let push arg =
			[%expr Java.push_object ([%e conv_to (mk_ident [ arg ])])]
		and call mid =
			conv_of [%expr Java.call_object obj [%e mk_ident [ mid ]]]
		and call_static mid =
			conv_of [%expr Java.call_object_static __cls [%e mk_ident [ mid ]]]
		and read_field fid =
			conv_of [%expr Java.read_field_object obj [%e mk_ident [ fid ]]]
		and write_field fid =
			[%expr Java.write_field_object ([%e conv_to (mk_ident [ fid ])])]
		and read_field_static fid =
			conv_of [%expr Java.read_field_static_object obj [%e mk_ident [ fid ]]]
		and write_field_static fid =
			[%expr Java.write_field_static_object ([%e conv_to (mk_ident [ fid ])])]
		in
		{ sigt = "L" ^ cn ^ ";"; push; call; call_static;
			read_field; write_field; read_field_static; write_field_static }
	in

	function
	| [%type: unit] as t			->
		let disabled _ = Location.raise_errorf ~loc:t.ptyp_loc
			"unit can only be a return type"
		and call mid =
			mk_call_dot_s ("Java", "call_void") [ "obj"; mid ]
		and call_static mid =
			mk_call_dot_s ("Java", "call_static_void") [ "__cls"; mid ]
		in
		{ sigt = "V"; push = disabled; call; call_static;
			read_field = disabled; write_field = disabled;
			read_field_static = disabled; write_field_static = disabled }

	| [%type: _] as t				->
		let d _ = Location.raise_errorf ~loc:t.ptyp_loc
			"`_' cannot be used here"
		in
		{ sigt = ""; push = d; call = d; call_static = d; read_field = d;
			write_field = d; read_field_static = d; write_field_static = d }

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
		let mn = module_name name in
		t_class name
			(fun v -> [%expr [%e mk_ident [ mn; "to_obj" ]] [%e v]])
			(fun obj -> [%expr let r = [%e obj] in
				if r == Java.null then failwith "null obj"
				else [%e mk_ident [ mn; "of_obj_unsafe" ]] r])

	| [%type: [%t? { ptyp_desc = Ptyp_constr ({ txt = Lident name }, []) }] option]
			when Hashtbl.mem known_classes name ->
		let mn = module_name name in
		t_class name
			(fun v -> [%expr match [%e v] with
				| Some arg	-> [%e mk_ident [ mn; "to_obj" ]] arg
				| None		-> Java.null])
			(fun obj -> [%expr let r = [%e obj] in
				if r == Java.null then None
				else Some ([%e mk_ident [ mn; "of_obj_unsafe" ]] r)])

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
	let rec is_static =
		function
		| ({ txt = "static" }, PStr []) :: _ -> true
		| []		-> false
		| _ :: tl	-> is_static tl
	in

	function
	| { pcf_desc = Pcf_method ({ txt = name }, visi, impl); pcf_loc = loc;
			pcf_attributes }	->
		begin match impl with
		| _ when visi <> Public				->
			Location.raise_errorf ~loc "Private method"
		| Cfk_concrete (Fresh, { pexp_desc = Pexp_poly (
				{ pexp_desc = Pexp_constant (Pconst_string (jname, None)) },
				Some mtype) })				->
			let m = name, jname, lazy (unwrap_method_type mtype) in
			if is_static pcf_attributes then `Method_static m else `Method m
		| Cfk_concrete (Fresh, { pexp_desc = Pexp_poly (
				{ pexp_loc = loc }, _) })	->
			Location.raise_errorf ~loc "Expecting Java method name"
		| Cfk_concrete (Fresh,
				{ pexp_loc = loc })			->
			Location.raise_errorf ~loc "Expecting method signature"
		| Cfk_virtual _						->
			Location.raise_errorf ~loc "Virtual method"
		| Cfk_concrete (Override, _)		->
			Location.raise_errorf ~loc "Override method"
		end

	| { pcf_desc = Pcf_val ({ txt = name }, mut, impl); pcf_loc = loc;
			pcf_attributes }	->
		begin match impl with
		| Cfk_concrete (Fresh, { pexp_desc = Pexp_constraint (
				{ pexp_desc = Pexp_constant (Pconst_string (jname, None)) },
				ftype ) })					->
			let f = name, jname, lazy (unwrap_core_type ftype), mut = Mutable in
			if is_static pcf_attributes then `Field_static f else `Field f
		| Cfk_concrete (Fresh, { pexp_desc = Pexp_constraint (
				{ pexp_loc = loc }, _ ) })	->
			Location.raise_errorf ~loc "Expecting Java field name"
		| Cfk_concrete (Fresh,
				{ pexp_loc = loc})			->
			Location.raise_errorf ~loc "Expecting field type"
		| Cfk_virtual _						->
			Location.raise_errorf ~loc "Virtual field"
		| Cfk_concrete (Override, _)		->
			Location.raise_errorf ~loc "Override field"
		end

	| { pcf_desc = Pcf_initializer { pexp_desc =
			Pexp_constraint ({ pexp_desc = Pexp_ident { txt = Lident name } },
				ctype) } }	->
		let rec check_ret_any =
			function
			| { ptyp_desc = Ptyp_arrow (_, _, r) }	-> check_ret_any r
			| { ptyp_desc = Ptyp_any }				-> ()
			| { ptyp_loc = loc }					->
				Location.raise_errorf ~loc "Constructor must returns `_'"
		in
		check_ret_any ctype;
		`Constructor (name, lazy (fst (unwrap_method_type ctype)))
	| { pcf_desc = Pcf_initializer { pexp_desc = Pexp_constraint (
			{ pexp_loc = loc }, _) } }	->
		Location.raise_errorf ~loc "Expecting constructor name"
	| { pcf_desc = Pcf_initializer { pexp_loc = loc } }	->
		Location.raise_errorf ~loc "Expecting constructor"

	| { pcf_loc = loc } -> Location.raise_errorf ~loc "Unsupported"

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

let mk_let id expr = [%stri let [%p Pat.var (mk_loc id)] = [%e expr]]
let mk_cstr s = Exp.constant (Const.string s)

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
	let items =

		let gen_method name args wrap call =
			let args = List.mapi (fun i _ -> arg_name i) args
			and pushs = List.mapi (fun i ti -> ti.push (arg_name i)) args in
			mk_let name (wrap (gen_func args (mk_sequence (pushs @ [ call ]))))

		and gen_field name mut read write =
			let getter = mk_let ("get'" ^ name) read
			and setter = mk_let ("set'" ^ name) write in
			if mut then [ getter; setter ] else [ getter ]
		in

		let wrap_no_args args =
			if args = []
			then (fun body -> [%expr (fun () -> [%e body])])
			else (fun body -> body)
		in

		List.fold_right (fun field items ->
		match field with
		| `Method (name, jname, sigt)			->
			let args, ret as sigt = Lazy.force sigt in
			let mid = add_global (`Method (jname, sigt)) in
			gen_method name args
				(fun body -> [%expr (fun obj -> [%e body])])
				(ret.call mid)
			:: items

		| `Method_static (name, jname, sigt)	->
			let args, ret as sigt = Lazy.force sigt in
			let mid = add_global (`Method (jname, sigt)) in
			gen_method name args (wrap_no_args args)
				(ret.call_static mid)
			:: items

		| `Field (name, jname, ti, mut)			->
			let ti = Lazy.force ti in
			let fid = add_global (`Field (jname, ti)) in
			gen_field name mut
				[%expr (fun obj -> [%e ti.read_field fid])]
				[%expr (fun obj v -> [%e ti.write_field fid])]
			@ items

		| `Field_static (name, jname, ti, mut)	->
			let ti = Lazy.force ti in
			let fid = add_global (`Field_static (jname, ti)) in
			gen_field name mut
				[%expr (fun obj -> [%e ti.read_field_static fid])]
				[%expr (fun obj v -> [%e ti.write_field_static fid])]
			@ items

		| `Constructor (name, args)				->
			let args = Lazy.force args in
			let cid = add_global (`Constructor args) in
			gen_method name args (wrap_no_args args)
				[%expr Java.new_ __cls [%e mk_ident [ cid ]]]
			:: items

	) fields [] in

	(* Globals *)
	let items = List.fold_left (fun items (id, g) ->
		let expr = match g with
			| `Method (name, sigt)			->
				let name, sigt = mk_cstr name, mk_cstr (jni_meth_sigt sigt) in
				[%expr Jclass.get_meth __cls [%e name] [%e sigt]]
			| `Method_static (name, sigt)	->
				let name, sigt = mk_cstr name, mk_cstr (jni_meth_sigt sigt) in
				[%expr Jclass.get_meth_static __cls [%e name] [%e sigt]]
			| `Field (name, ti)				->
				let name, ti = mk_cstr name, mk_cstr ti.sigt in
				[%expr Jclass.get_field __cls [%e name] [%e ti]]
			| `Field_static (name, ti)		->
				let name, ti = mk_cstr name, mk_cstr ti.sigt in
				[%expr Jclass.get_field_static __cls [%e name] [%e ti]]
			| `Constructor args				->
				let sigt = mk_cstr ("(" ^ concat_sigt args ^ ")V") in
				[%expr Jclass.get_constructor __cls [%e sigt]]
		in
		mk_let id expr :: items
	) items !globals in

	(* Pervasives *)
	let items = [
		[%stri type t];

		[%stri let __cls = Jclass.find_class
			[%e mk_cstr (java_class_fmt java_name)]];

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
