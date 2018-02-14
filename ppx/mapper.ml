open Ast_mapper
open Ast_helper
open Longident
open Parsetree
open Asttypes
open Ast_tools

(** Translate a core_type into a Type_info.t
	`class_name` and `java_path` are used to generate different signature
	for the current class and `rec_classes` for mutually recursive classes
	Raises a location error if the type is not supported *)
let rec translate_type class_name java_path rec_classes =
	let no_conv expr = expr in
	let type_info ?(conv_to=no_conv) ?(conv_of=no_conv) sigt suffix type_ =
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
		type_info ~conv_to ~conv_of sigt "object" type_

	and ti sigt suffix type_ = type_info (mk_cstr sigt) suffix type_ in

	let rec ti_array t =
		let open Type_info in
		let t = ti_array_transl t in
		let sigt = [%expr "[" ^ [%e t.sigt]] in
		type_info sigt "array" [%type: [%t t.type_] Jarray.t]

	and ti_array_transl =
		function
		| [%type: byte]				-> ti "B" "byte" [%type: Jarray.jbyte]
		| [%type: short]			-> ti "S" "short" [%type: Jarray.jshort]
		| [%type: double]			-> ti "D" "double" [%type: Jarray.jdouble]
		| [%type: [%t? t] value]	->
			ti "Ljuloo/javacaml/Value;" "value" [%type: [%t t] Jarray.jvalue]
		| [%type: [%t? t] array]	-> ti_array t
		| [%type: [%t? _] option] as t ->
			Location.raise_errorf ~loc:t.ptyp_loc "Unsupported type"
		| t -> translate_type class_name java_path rec_classes t
	in

	let mn =
		function
		| Lident cn when cn = class_name ->
			(fun s -> mk_loc (Lident s)),
			mk_cstr java_path
		| Lident cn as id when List.mem_assoc cn rec_classes ->
			let mn = Gen.module_name id in
			(fun s -> mk_loc (Ldot (mn, s))),
			mk_cstr (List.assoc cn rec_classes)
		| id ->
			let mn = Gen.module_name id in
			(fun s -> mk_loc (Ldot (mn, s))),
			[%expr [%e mk_dot mn "__class_name" ] ()]
	in

	function
	| ([%type: unit]
	| [%type: int option]
	| [%type: bool option]
	| [%type: byte option]
	| [%type: short option]
	| [%type: int32 option]
	| [%type: long option]
	| [%type: char option]
	| [%type: float option]
	| [%type: double option]
	| [%type: Java.obj option]
	| [%type: value]
	| [%type: value option]
	| [%type: option]
	| [%type: array]
	| [%type: array option]) as t	->
		(* Disable a few types that should not be valid class names *)
		Location.raise_errorf ~loc:t.ptyp_loc "This type cannot be used here"
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
	| [%type: [%t? t] array]		-> ti_array t
	| [%type: [%t? t] array option]	->
		let t = ti_array t in
		type_info t.sigt "array_opt" [%type: [%t t.type_] option]

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

let translate_field class_name java_path rec_classes =
	let transl_type = translate_type class_name java_path rec_classes in
	let transl_args = List.map transl_type
	and transl_ret =
		function
		| [%type: unit]		-> `Void
		| t					-> `Ret (transl_type t)
	in
	function
	| `Method (name, java_name, (args, ret), static)	->
		let m = name, java_name, (transl_args args, transl_ret ret) in
		if static then `Method_static m else `Method m
	| `Field (name, java_name, typ, mut, static)		->
		let f = name, java_name, transl_type typ, mut in
		if static then `Field_static f else `Field f
	| `Constructor (name, args)							->
		`Constructor (name, transl_args args)

(** Map `class` with the `%java` extension *)
let structure_item mapper =
	let java_path_fmt = String.map (function '.' -> '/' | c -> c) in
	function
	| { pstr_desc = Pstr_extension (({ txt = "java" }, PStr [
			{ pstr_desc = Pstr_class classes }
		]), _) }	->
		let unwrap cls =
			let name, java_path, fields = Unwrap.class_ cls in
			name, java_path_fmt java_path, fields
		in
		let classes = List.map unwrap classes in
		let rec_classes = List.map (fun (n, p, _) -> n, p) classes in
		let gen (name, java_path, fields) =
			let transl = translate_field name java_path rec_classes in
			Gen.class_ name java_path (List.map transl fields)
		in
		begin match List.map gen classes with
		| [ cls ]	-> Str.module_ cls
		| classes	-> Str.rec_module classes
		end
	| item			-> default_mapper.structure_item mapper item

let mapper _ = { default_mapper with structure_item }

let () = register "ocaml-java-ppx" mapper
