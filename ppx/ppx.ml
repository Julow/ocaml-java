open Ast_mapper
open Ast_helper
open Parsetree
open Asttypes
open Longident

(* - *)

let rec module_name =
	function
	| Ldot (l, r)	-> Ldot (l, String.capitalize_ascii r)
	| Lident n		-> Lident (String.capitalize_ascii n)
	| Lapply _		-> assert false

let java_class_fmt = String.map (function '.' -> '/' | c -> c)

let arg_name = Printf.sprintf "x%d"

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

let mk_dot l r = Exp.ident (mk_loc (Ldot (l, r)))

let rec mk_sequence =
	function
	| exp :: []	-> exp
	| exp :: tl	-> Exp.sequence exp (mk_sequence tl)
	| []		-> assert false

let mk_let id expr = [%stri let [%p Pat.var (mk_loc id)] = [%e expr]]
let mk_val id type_ = Sig.value (Val.mk (mk_loc id) type_)

let mk_cstr s = Exp.constant (Const.string s)

let mk_fun args body =
	let inc arg body = Exp.fun_ Nolabel None (Pat.var (mk_loc arg)) body in
	List.fold_right inc args body

let mk_arrow args ret =
	let inc arg arrow = [%type: [%t arg] -> [%t arrow]] in
	List.fold_right inc args ret

let opti_string_concat exp =
	let rec flatten acc =
		function
		| { pexp_desc = Pexp_apply ({ pexp_desc = Pexp_ident
				{ txt = Lident "^" } }, [ (_, l); (_, r) ])}		->
			flatten (flatten acc l) r
		| { pexp_desc = Pexp_constant (Pconst_string (s, None)) }	->
			`S s :: acc
		| e -> `E e :: acc
	in
	let rec opti acc =
		function
		| `S a :: `S b :: tl	-> opti acc (`S (b ^ a) :: tl)
		| `E e :: tl			-> opti (e :: acc) tl
		| `S a :: `E e :: tl	-> opti (e :: opti acc [ `S a ]) tl
		| [ `S "" ]				-> acc
		| [ `S a ]				-> mk_cstr a :: acc
		| []					-> acc
	in
	let rec concat =
		function
		| [ e ]		-> [%expr [%e e]]
		| e :: tl	-> [%expr [%e e] ^ [%e concat tl]]
		| []		-> mk_cstr ""
	in
	concat (opti [] (flatten [] exp))

(* Type info *)

(* The variable `obj` is expected to be defined,
	`write_field` expects the variable `v` to be defined
	`call_static` expects `__cls` *)
type type_info = {
	sigt : expression;
	type_ : core_type;
	push : string -> expression;
	call : string -> expression;
	call_static : string -> expression;
	read_field : string -> expression;
	write_field : string -> expression;
	read_field_static : string -> expression;
	write_field_static : string -> expression
}

let type_info ~push ~call ~call_static ~read_field ~write_field
	~read_field_static ~write_field_static sigt type_ conv_to conv_of =
	let push arg =
		[%expr [%e push] ([%e conv_to (mk_ident [ arg ])])]
	and call mid =
		conv_of [%expr [%e call] (to_obj obj) [%e mk_ident [ mid ]]]
	and call_static mid =
		conv_of [%expr [%e call_static] __cls [%e mk_ident [ mid ]]]
	and read_field fid =
		conv_of [%expr [%e read_field] (to_obj obj) [%e mk_ident [ fid ]]]
	and write_field fid =
		[%expr [%e write_field] (to_obj obj) [%e mk_ident [ fid ]]
			[%e conv_to [%expr v]]]
	and read_field_static fid =
		conv_of [%expr [%e read_field_static] __cls [%e mk_ident [ fid ]]]
	and write_field_static fid =
		[%expr [%e write_field_static] __cls [%e mk_ident [ fid ]]
			[%e conv_to [%expr v]]]
	in
	{ sigt; type_; push; call; call_static; read_field; write_field;
		read_field_static; write_field_static }

let rec concat_sigt =
	function
	| [ arg ]	-> [%expr [%e arg.sigt]]
	| arg :: tl	-> [%expr [%e arg.sigt] ^ [%e concat_sigt tl]]
	| []		-> mk_cstr ""

let jni_meth_sigt (args, ret) =
	[%expr "(" ^ [%e concat_sigt args] ^ ")" ^ [%e ret.sigt]]

(* Unwrapper *)

(* `near_classes` is the assoc list (class_name, java_path) for  *)
type context = {
	class_name : string;
	java_path : string;
	near_classes : (string * string) list
}

let unwrap_core_type ctx =
	let ti sigt suffix type_ conv_to conv_of =
		let id prefix = mk_dot (Lident "Java") (prefix ^ suffix) in
		type_info
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
			let mn = module_name id in
			(fun s -> mk_loc (Ldot (mn, s))),
			mk_cstr (List.assoc cn ctx.near_classes)
		| id ->
			let mn = module_name id in
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
		{ sigt = mk_cstr "V"; type_ = t; push = d; call; call_static;
			read_field = d; write_field = d;
			read_field_static = d; write_field_static = d }

	| [%type: _] as t				->
		let d _ = Location.raise_errorf ~loc:t.ptyp_loc
			"`_' cannot be used here"
		in
		{ sigt = Exp.unreachable (); type_ = t; push = d; call = d;
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

let rec unwrap_method_type ctx =
	function
	| [%type: [%t? lhs] -> [%t? rhs]]	->
		let args, ret = match rhs with
			| [%type: [%t? _] -> [%t? _]]	-> unwrap_method_type ctx rhs
			| _								-> [], unwrap_core_type ctx rhs
		in
		unwrap_core_type ctx lhs :: args, ret
	| t								-> [], unwrap_core_type ctx t

let unwrap_class_field ctx =
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
			let m = name, jname, unwrap_method_type ctx mtype in
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
			let f = name, jname, unwrap_core_type ctx ftype, mut = Mutable in
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
		begin match unwrap_method_type ctx ctype with
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
let unwrap_class =
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
			List.map (unwrap_class_field ctx) pcstr_fields)
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

let gen_class_sigt (_, _, fields) =
	let items =
		let gen_method name args wrap ret =
			let args = List.map (fun ti -> ti.type_) args in
			mk_val name (wrap (mk_arrow args ret))

		and gen_field name mut read write =
			let getter = mk_val ("get'" ^ name) read
			and setter = mk_val ("set'" ^ name) write in
			if mut then [ getter; setter ] else [ getter ]

		and wrap_no_args args t =
			if args = [] then [%type: unit -> [%t t]] else t
		in

		List.fold_right (fun field items ->
		match field with
		| `Method (name, _, (args, ret))		->
			gen_method name args
				(fun t -> [%type: t -> [%t t]])
				ret.type_
			:: items

		| `Method_static (name, _, (args, ret))	->
			gen_method name args (wrap_no_args args) ret.type_
			:: items

		| `Field (name, jname, ti, mut)			->
			gen_field name mut
				[%type: t -> [%t ti.type_]]
				[%type: t -> [%t ti.type_] -> unit]
			@ items

		| `Field_static (name, jname, ti, mut)	->
			gen_field name mut
				[%type: unit -> [%t ti.type_]]
				[%type: [%t ti.type_] -> unit]
			@ items

		| `Constructor (name, args)				->
			gen_method name args (wrap_no_args args) [%type: t]
			:: items

	) fields [] in

	let items = [

		[%sigi: type t];

		[%sigi: val __class_name : unit -> string];

		[%sigi: external to_obj : t -> Java.obj = "%identity"];

		[%sigi: external of_obj_unsafe : Java.obj -> t = "%identity"];

		[%sigi: val of_obj : Java.obj -> t];

	] @ items in

	Mty.signature items

let gen_class_impl (_, java_name, fields) =
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
			mk_let name (wrap (mk_fun args (mk_sequence (pushs @ [ call ]))))

		and gen_field name mut read write =
			let getter = mk_let ("get'" ^ name) read
			and setter = mk_let ("set'" ^ name) write in
			if mut then [ getter; setter ] else [ getter ]

		and wrap_no_args args body =
			if args = [] then [%expr (fun () -> [%e body])] else body
		in

		List.fold_right (fun field items ->
		match field with
		| `Method (name, jname, (args, ret as sigt))		->
			let mid = add_global (`Method (jname, sigt)) in
			gen_method name args
				(fun body -> [%expr (fun obj -> [%e body])])
				(ret.call mid)
			:: items

		| `Method_static (name, jname, (args, ret as sigt))	->
			let mid = add_global (`Method_static (jname, sigt)) in
			gen_method name args (wrap_no_args args) (ret.call_static mid)
			:: items

		| `Field (name, jname, ti, mut)			->
			let fid = add_global (`Field (jname, ti)) in
			gen_field name mut
				[%expr (fun obj -> [%e ti.read_field fid])]
				[%expr (fun obj v -> [%e ti.write_field fid])]
			@ items

		| `Field_static (name, jname, ti, mut)	->
			let fid = add_global (`Field_static (jname, ti)) in
			gen_field name mut
				[%expr (fun () -> [%e ti.read_field_static fid])]
				[%expr (fun v -> [%e ti.write_field_static fid])]
			@ items

		| `Constructor (name, args)				->
			let cid = add_global (`Constructor args) in
			gen_method name args (wrap_no_args args)
				[%expr of_obj_unsafe (Java.new_ __cls [%e mk_ident [ cid ]])]
			:: items

	) fields [] in

	(* Globals *)
	let items = List.fold_left (fun items (id, g) ->
		let expr = match g with
			| `Method (name, sigt)			->
				let name = mk_cstr name
				and sigt = opti_string_concat (jni_meth_sigt sigt) in
				[%expr Jclass.get_meth __cls [%e name] [%e sigt]]
			| `Method_static (name, sigt)	->
				let name = mk_cstr name
				and sigt = opti_string_concat (jni_meth_sigt sigt) in
				[%expr Jclass.get_meth_static __cls [%e name] [%e sigt]]
			| `Field (name, ti)				->
				let name = mk_cstr name in
				[%expr Jclass.get_field __cls [%e name] [%e ti.sigt]]
			| `Field_static (name, ti)		->
				let name = mk_cstr name in
				[%expr Jclass.get_field_static __cls [%e name] [%e ti.sigt]]
			| `Constructor args				->
				let sigt = opti_string_concat
					[%expr "(" ^ [%e concat_sigt args] ^ ")V"] in
				[%expr Jclass.get_constructor __cls [%e sigt]]
		in
		mk_let id expr :: items
	) items !globals in

	(* Pervasives *)
	let class_name = mk_cstr java_name in
	let items = [
		[%stri type t];

		[%stri let __class_name () = [%e class_name]];

		[%stri let __cls = Jclass.find_class [%e class_name]];

		[%stri external to_obj : t -> Java.obj = "%identity"];

		[%stri external of_obj_unsafe : Java.obj -> t = "%identity"];

		[%stri let of_obj obj =
			if Java.instanceof obj __cls
			then of_obj_unsafe obj
			else failwith "of_obj"]

	] @ items in

	Mod.structure items

let gen_class (class_name, _, _ as cls) =
	let impl = gen_class_impl cls
	and sigt = gen_class_sigt cls in
	let mn = String.capitalize_ascii class_name in
	Mb.mk (mk_loc mn) (Mod.constraint_ impl sigt)

(* Mapper *)

let structure_item mapper =
	function
	| { pstr_desc = Pstr_extension (({ txt = "java" }, PStr [
			{ pstr_desc = Pstr_class classes }
		]), _) }	->
		let classes = List.map unwrap_class classes in
		let near_classes = List.map (fun (n, p, _) -> n, p) classes in
		let gen (name, java_path, unwrap) =
			gen_class (name, java_path, (unwrap near_classes))
		in
		begin match List.map gen classes with
		| [ cls ]	-> Str.module_ cls
		| classes	-> Str.rec_module classes
		end
	| item			-> default_mapper.structure_item mapper item

let mapper _ = { default_mapper with structure_item }

let () = register "ocaml-java-ppx" mapper
