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

	(* Defines "id" in `body` *)
	let load_id index load body =
		let index = Exp.constant (Const.int index) in
		[%expr
			let id =
				let id = Array.unsafe_get __cls [%e index] in
				if id == Obj.magic 0 then begin
					let id = [%e load] in
					Array.unsafe_set __cls [%e index] (Obj.magic id);
					id
				end
				else Obj.magic id
			in
			[%e body]]

	(* Defines "cls" in `body`,
		assumes the class is loaded (do not calls __load_cls) *)
	and load_cls_unsafe body =
		[%expr let cls = Array.unsafe_get __cls 0 in [%e body]]
	in

	(* Expects an "id" binding the method ID *)
	let meth_call static ret =
		match static, ret with
		| false, `Void		-> [%expr Jcall.call_void obj id]
		| true, `Void		-> [%expr Jcall.call_static_void cls id]
		| false, `Ret ti	-> ti.call
		| true, `Ret ti		-> ti.call_static
	in

	fun add_global ->
	function
	| `Method (name, jname, (args, ret as sigt))		->
		let index = add_global ()
		and sigt = opti_string_concat (Type_info.meth_sigt sigt) in
		let load = load_id index
			[%expr Jclass.get_meth (__load_cls ())
				[%e mk_cstr jname] [%e sigt]]
		and wrap body = [%expr (fun obj -> [%e body])] in
		[ meth_impl name args wrap (load (meth_call false ret)) ]

	| `Method_static (name, jname, (args, ret as sigt))	->
		let index = add_global ()
		and sigt = opti_string_concat (Type_info.meth_sigt sigt) in
		let load body = load_id index
			[%expr Jclass.get_meth_static (__load_cls ())
				[%e mk_cstr jname] [%e sigt]]
			(load_cls_unsafe body) in
		[ meth_impl name args (wrap_no_args args) (load (meth_call true ret)) ]

	| `Field (name, jname, ti, mut)			->
		let index = add_global () in
		let load = load_id index
			[%expr Jclass.get_field (__load_cls ())
				[%e mk_cstr jname] [%e ti.sigt]] in
		field_impl name mut
			[%expr (fun obj -> [%e load ti.read_field])]
			[%expr (fun obj v -> [%e load ti.write_field])]

	| `Field_static (name, jname, ti, mut)	->
		let index = add_global () in
		let load body = load_id index
			[%expr Jclass.get_field_static (__load_cls ())
				[%e mk_cstr jname] [%e ti.sigt]]
				(load_cls_unsafe body) in
		field_impl name mut
			[%expr (fun () -> [%e load ti.read_field_static])]
			[%expr (fun v -> [%e load ti.write_field_static])]

	| `Constructor (name, args)				->
		let index = add_global ()
		and sigt = opti_string_concat
			[%expr "(" ^ [%e concat_sigt args] ^ ")V"] in
		let load body = load_id index
			[%expr Jclass.get_constructor (__load_cls ())
				[%e sigt]]
			(load_cls_unsafe body) in
		[ meth_impl name args (wrap_no_args args)
			(load [%expr Jcall.new_ cls id]) ]

(* Generates implementation *)
let class_impl path_name class_variants fields =
	(* Use a ref to count globals from `impl_item` *)
	let global_count = ref 1 in
	let add_global () =
		let id = !global_count in
		incr global_count;
		id
	in

	(* Items *)
	let items = List.fold_right (fun field items ->
		impl_item add_global field @ items
	) fields [] in

	(* Intro *)
	let cls_array = Array.(make !global_count [%expr Obj.magic 0] |> to_list)
	and class_name = mk_cstr path_name in
	let items = [

		[%stri type c = [%t class_variants]];
		[%stri type 'a t' = ([> c] as 'a) Java.obj];
		[%stri type t = c Java.obj];

		[%stri let __class_name () = [%e class_name]];

		[%stri let __cls : Jclass.t array = [%e Exp.array cls_array]];

		[%stri let __load_cls () =
			let cls = Array.unsafe_get __cls 0 in
			if cls == Obj.magic 0 then begin
				let cls = Jclass.find_class [%e class_name] in
				Array.unsafe_set __cls 0 cls;
				cls
			end
			else cls];

		[%stri external of_obj_unsafe : 'a Java.obj -> t = "%identity"];

		[%stri let of_obj obj =
			if Java.instanceof obj (__load_cls ())
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
