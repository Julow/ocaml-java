open Parsetree
open Ast_helper
open Longident
open Asttypes
open Ast_tools

let java_class_fmt = String.map (function '.' -> '/' | c -> c)

(* `near_classes` is the assoc list (class_name, java_path) for  *)
type context = {
	class_name : string;
	java_path : string;
	near_classes : (string * string) list
}

let core_type ctx =
	let ti sigt suffix type_ conv_to conv_of =
		let id prefix = mk_dot (Lident "Java") (prefix ^ suffix) in
		Type_info.create
			~push:(id "push_")
			~call:(id "call_")
			~call_static:(id "call_static_")
			~read_field:(id "read_field_")
			~write_field:(id "write_field_")
			~read_field_static:(id "read_field_static_")
			~write_field_static:(id "write_field_static_")
			sigt type_ conv_to conv_of
	in

	let ti_class mn java_path type_ conv_to conv_of =
		let sigt = [%expr "L" ^ [%e java_path] ^ ";"] in
		ti sigt "object" type_ conv_to conv_of

	and ti sigt suffix type_ =
		let no_conv expr = expr in
		ti (mk_cstr sigt) suffix type_ no_conv no_conv
	in

	let mn =
		function
		| Lident cn when cn = ctx.class_name ->
			(fun s -> mk_loc (Lident s)),
			mk_cstr ctx.java_path
		| Lident cn as id when List.mem_assoc cn ctx.near_classes ->
			let mn = Gen.module_name id in
			(fun s -> mk_loc (Ldot (mn, s))),
			mk_cstr (List.assoc cn ctx.near_classes)
		| id ->
			let mn = Gen.module_name id in
			(fun s -> mk_loc (Ldot (mn, s))),
			[%expr [%e mk_dot mn "__class_name" ] ()]
	in

	function
	| [%type: unit] as t			->
		let d _ = Location.raise_errorf ~loc:t.ptyp_loc
			"unit can only be a return type"
		and call mid =
			[%expr Java.call_void (to_obj obj) [%e mk_ident [ mid ]]]
		and call_static mid =
			[%expr Java.call_static_void __cls [%e mk_ident [ mid ]]]
		in
		Type_info.{ sigt = mk_cstr "V"; type_ = t; push = d; call;
			call_static; read_field = d; write_field = d;
			read_field_static = d; write_field_static = d }

	| [%type: _] as t				->
		let d _ = Location.raise_errorf ~loc:t.ptyp_loc
			"`_' cannot be used here"
		in
		Type_info.{ sigt = Exp.unreachable (); type_ = t; push = d; call = d;
			call_static = d; read_field = d; write_field = d;
			read_field_static = d; write_field_static = d }

	| [%type: int] as t				-> ti "I" "int" t
	| [%type: bool] as t			-> ti "Z" "bool" t
	| [%type: byte]					-> ti "B" "byte" [%type: int]
	| [%type: short]				-> ti "S" "short" [%type: int]
	| [%type: int32]				-> ti "I" "int32" [%type: Int32.t]
	| [%type: long]					-> ti "J" "long" [%type: Int64.t]
	| [%type: char] as t			-> ti "C" "char" t
	| [%type: float] as t			-> ti "F" "float" t
	| [%type: double]				-> ti "D" "double" [%type: float]
	| [%type: string] as t			-> ti "Ljava/lang/String;" "string" t
	| [%type: string option] as t	-> ti "Ljava/lang/String;" "string_opt" t
	| [%type: [%t? t] value]		-> ti "Ljuloo/javacaml/Value;" "value" t
	| [%type: [%t? t] value option]	->
		ti "Ljuloo/javacaml/Value;" "value_opt" [%type: [%t t] option]
	| [%type: Java.obj] as t		-> ti "Ljava/lang/Object;" "object" t

	| [%type: [%t? { ptyp_desc = Ptyp_constr ({ txt = id }, []) }]] ->
		let mn, java_path = mn id in
		ti_class mn java_path (Typ.constr (mn "t") [])
			(fun v -> [%expr [%e Exp.ident (mn "to_obj")] [%e v]])
			(fun obj -> [%expr let r = [%e obj] in
				if r == Java.null then failwith "null obj"
				else [%e Exp.ident (mn "of_obj_unsafe") ] r])

	| [%type: [%t? { ptyp_desc = Ptyp_constr ({ txt = id }, []) }] option] ->
		let mn, java_path = mn id in
		ti_class mn java_path (Typ.constr (mn "t") [])
			(fun v -> [%expr match [%e v] with
				| Some arg	-> [%e Exp.ident (mn "to_obj") ] arg
				| None		-> Java.null])
			(fun obj -> [%expr let r = [%e obj] in
				if r == Java.null then None
				else Some ([%e Exp.ident (mn "of_obj_unsafe") ] r)])

	| { ptyp_loc = loc } -> Location.raise_errorf ~loc "Unsupported type"

let rec method_type ctx =
	function
	| [%type: [%t? lhs] -> [%t? rhs]]	->
		let args, ret = match rhs with
			| [%type: [%t? _] -> [%t? _]]	-> method_type ctx rhs
			| _								-> [], core_type ctx rhs
		in
		core_type ctx lhs :: args, ret
	| t								-> [], core_type ctx t

let class_field ctx =
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
			let m = name, jname, method_type ctx mtype in
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
			let f = name, jname, core_type ctx ftype, mut = Mutable in
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
			Pexp_constraint ({ pexp_desc = Pexp_ident { txt = Lident name };
					pexp_loc = loc}, ctype) } }	->
		begin match method_type ctx ctype with
		| args, { sigt = { pexp_desc = Pexp_unreachable }}	->
			`Constructor (name, args)
		| _ -> Location.raise_errorf ~loc "Constructor must returns `_'"
		end
	| { pcf_desc = Pcf_initializer { pexp_desc = Pexp_constraint (
			{ pexp_loc = loc }, _) } }	->
		Location.raise_errorf ~loc "Expecting constructor name"
	| { pcf_desc = Pcf_initializer { pexp_loc = loc } }	->
		Location.raise_errorf ~loc "Expecting constructor"

	| { pcf_loc = loc } -> Location.raise_errorf ~loc "Unsupported"

(** Returns the tuple (class name, java class name, fields)
		where fields is
			[`Method (meth_name, path, (near_classes -> (args, ret types)))]
	Raises `Invalid_argument` if the class is not formatted correctly *)
let class_ =
	function
	| {	pci_name = { txt = class_name };
		pci_expr = { pcl_desc = Pcl_fun (Nolabel, None,
				{ ppat_desc = Ppat_constant (Pconst_string (java_path, None)) },
				{ pcl_desc = Pcl_structure {
					pcstr_self = { ppat_desc = Ppat_any };
					pcstr_fields } }) } } ->
		let java_path = java_class_fmt java_path in
		(class_name, java_path, fun near_classes ->
			let ctx = { class_name; java_path; near_classes } in
			List.map (class_field ctx) pcstr_fields)
	| { pci_expr = { pcl_desc = Pcl_fun (_, _, _, { pcl_desc = Pcl_structure {
				pcstr_self = { ppat_desc; ppat_loc = loc }
			}})} } when ppat_desc <> Ppat_any ->
		Location.raise_errorf ~loc "self is not allowed"
	| { pci_expr = { pcl_desc = Pcl_fun (_, _, { ppat_desc =
			Ppat_constant (Pconst_string _) }, { pcl_loc = loc }) } } ->
		Location.raise_errorf ~loc "Expecting object"
	| { pci_loc = loc }		->
		Location.raise_errorf ~loc "Expecting Java class path"
