open Parsetree
open Longident
open Ast_helper
open Ast_tools
open Type_info

(** Generates the module for a class (see `class_` below) *)

let rec module_name =
	function
	| Ldot (l, r)	-> Ldot (l, String.capitalize_ascii r)
	| Lident n		-> Lident (String.capitalize_ascii n)
	| Lapply _		-> assert false

let arg_name = Printf.sprintf "x%d"

let meth_sigt name args wrap ret =
	let args = List.map (fun ti -> ti.type_) args in
	mk_val name (wrap (mk_arrow args ret))

let field_sigt name mut read write =
	let getter = mk_val ("get'" ^ name) read
	and setter = mk_val ("set'" ^ name) write in
	if mut then [ getter; setter ] else [ getter ]

let meth_impl name args wrap call =
	let args = List.mapi (fun i _ -> arg_name i) args
	and pushs = List.mapi (fun i ti -> ti.push (arg_name i)) args in
	mk_let name (wrap (mk_fun args (mk_sequence (pushs @ [ call ]))))

let field_impl name mut read write =
	let getter = mk_let ("get'" ^ name) read
	and setter = mk_let ("set'" ^ name) write in
	if mut then [ getter; setter ] else [ getter ]

(* Global (lookup of class handles, methods and fields ids) *)
let global =
	function
	| `GMethod (name, sigt)			->
		let name = mk_cstr name
		and sigt = opti_string_concat (Type_info.meth_sigt sigt) in
		[%expr Jclass.get_meth __cls [%e name] [%e sigt]]
	| `GMethod_static (name, sigt)	->
		let name = mk_cstr name
		and sigt = opti_string_concat (Type_info.meth_sigt sigt) in
		[%expr Jclass.get_meth_static __cls [%e name] [%e sigt]]
	| `GField (name, ti)			->
		let name = mk_cstr name in
		[%expr Jclass.get_field __cls [%e name] [%e ti.sigt]]
	| `GField_static (name, ti)		->
		let name = mk_cstr name in
		[%expr Jclass.get_field_static __cls [%e name] [%e ti.sigt]]
	| `GConstructor args			->
		let sigt = opti_string_concat
			[%expr "(" ^ [%e concat_sigt args] ^ ")V"] in
		[%expr Jclass.get_constructor __cls [%e sigt]]

(* Signature *)
let sigt_item =
	let wrap_no_args args t =
		if args = [] then [%type: unit -> [%t t]] else t
	and ret_type =
		function
		| `Void		-> [%type: unit]
		| `Ret ti	-> ti.type_
	in
	function
	| `Method (name, _, (args, ret))		->
		let wrap t = [%type: _ t' -> [%t t]] in
		[ meth_sigt name args wrap (ret_type ret) ]
	| `Method_static (name, _, (args, ret))	->
		[ meth_sigt name args (wrap_no_args args) (ret_type ret) ]
	| `Field (name, jname, ti, mut)			->
		field_sigt name mut
			[%type: _ t' -> [%t ti.type_]]
			[%type: _ t' -> [%t ti.type_] -> unit]
	| `Field_static (name, jname, ti, mut)	->
		field_sigt name mut
			[%type: unit -> [%t ti.type_]]
			[%type: [%t ti.type_] -> unit]
	| `Constructor (name, args)				->
		[ meth_sigt name args (wrap_no_args args) [%type: t] ]

(* Generates signature *)
let class_sigt class_variants fields =
	Mty.signature @@ [

		[%sigi: type c = [%t class_variants]];
		[%sigi: type 'a t' = ([> c] as 'a) Java.obj];
		[%sigi: type t = c Java.obj];

		[%sigi: val __class_name : unit -> string];

		[%sigi: val of_obj : 'a Java.obj -> t];

	]
	@ List.fold_right (fun field items -> sigt_item field @ items) fields []

(* Implementation *)
let impl_item =
	let wrap_no_args args body =
		if args = [] then [%expr (fun () -> [%e body])] else body
	in
	let meth_call static ret mid =
		let mide = mk_ident [ mid ] in
		match static, ret with
		| false, `Void		-> [%expr Java.call_void obj [%e mide ]]
		| true, `Void		-> [%expr Java.call_static_void __cls [%e mide ]]
		| false, `Ret ti	-> ti.call mid
		| true, `Ret ti		-> ti.call_static mid
	in
	fun add_global ->
	function
	| `Method (name, jname, (args, ret as sigt))		->
		let mid = add_global (`GMethod (jname, sigt)) in
		let wrap body = [%expr (fun obj -> [%e body])] in
		[ meth_impl name args wrap (meth_call false ret mid) ]

	| `Method_static (name, jname, (args, ret as sigt))	->
		let mid = add_global (`GMethod_static (jname, sigt)) in
		[ meth_impl name args (wrap_no_args args) (meth_call true ret mid) ]

	| `Field (name, jname, ti, mut)			->
		let fid = add_global (`GField (jname, ti)) in
		field_impl name mut
			[%expr (fun obj -> [%e ti.read_field fid])]
			[%expr (fun obj v -> [%e ti.write_field fid])]

	| `Field_static (name, jname, ti, mut)	->
		let fid = add_global (`GField_static (jname, ti)) in
		field_impl name mut
			[%expr (fun () -> [%e ti.read_field_static fid])]
			[%expr (fun v -> [%e ti.write_field_static fid])]

	| `Constructor (name, args)				->
		let cid = add_global (`GConstructor args) in
		[ meth_impl name args (wrap_no_args args)
			[%expr Java.new_ __cls [%e mk_ident [ cid ]]] ]

(* Generates implementation *)
let class_impl path_name class_variants fields =
	(* Use a ref to receive globals from `impl_item` and alloc an id *)
	let globals, add_global =
		let globals, count = ref [], ref 0 in
		globals, fun g ->
			let id = Printf.sprintf "__%d" !count in
			incr count;
			globals := (id, g) :: !globals;
			id
	in

	(* Items *)
	let items = List.fold_right (fun field items ->
		impl_item add_global field @ items
	) fields [] in

	(* Globals *)
	let items = List.fold_left (fun items (id, g) ->
		mk_let id (global g) :: items
	) items !globals in

	(* Intro *)
	let class_name = mk_cstr path_name in
	let items = [

		[%stri type c = [%t class_variants]];
		[%stri type 'a t' = ([> c] as 'a) Java.obj];
		[%stri type t = c Java.obj];

		[%stri let __class_name () = [%e class_name]];

		[%stri let __cls = Jclass.find_class [%e class_name]];

		[%stri external of_obj_unsafe : 'a Java.obj -> t = "%identity"];

		[%stri let of_obj obj =
			if Java.instanceof obj __cls
			then of_obj_unsafe obj
			else failwith "of_obj"]

	] @ items in

	Mod.structure items

(* Module sigt and impl *)
let class_ class_name path_name class_variants fields =
	let impl = class_impl path_name class_variants fields
	and sigt = class_sigt class_variants fields in
	let mn = String.capitalize_ascii class_name in
	Mb.mk (mk_loc mn) (Mod.constraint_ impl sigt)
