open Parsetree
open Longident
open Ast_helper
open Ast_tools
open Type_info

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

let global =
	function
	| `Method (name, sigt)			->
		let name = mk_cstr name
		and sigt = opti_string_concat (Type_info.meth_sigt sigt) in
		[%expr Jclass.get_meth __cls [%e name] [%e sigt]]
	| `Method_static (name, sigt)	->
		let name = mk_cstr name
		and sigt = opti_string_concat (Type_info.meth_sigt sigt) in
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

(* Signature *)
let sigt_item =
	let wrap_no_args args t =
		if args = [] then [%type: unit -> [%t t]] else t
	in
	function
	| `Method (name, _, (args, ret))		->
		[ meth_sigt name args (fun t -> [%type: t -> [%t t]]) ret.type_ ]
	| `Method_static (name, _, (args, ret))	->
		[ meth_sigt name args (wrap_no_args args) ret.type_ ]
	| `Field (name, jname, ti, mut)			->
		field_sigt name mut
			[%type: t -> [%t ti.type_]]
			[%type: t -> [%t ti.type_] -> unit]
	| `Field_static (name, jname, ti, mut)	->
		field_sigt name mut
			[%type: unit -> [%t ti.type_]]
			[%type: [%t ti.type_] -> unit]
	| `Constructor (name, args)				->
		[ meth_sigt name args (wrap_no_args args) [%type: t] ]

(* Generates signature *)
let class_sigt fields =
	let items = List.fold_right (fun field items ->
		sigt_item field @ items
	) fields [] in

	let items = [

		[%sigi: type t];

		[%sigi: val __class_name : unit -> string];

		[%sigi: external to_obj : t -> Java.obj = "%identity"];

		[%sigi: external of_obj_unsafe : Java.obj -> t = "%identity"];

		[%sigi: val of_obj : Java.obj -> t];

	] @ items in

	Mty.signature items

(* Implementation *)
let impl_item =
	let wrap_no_args args body =
		if args = [] then [%expr (fun () -> [%e body])] else body
	in
	fun add_global ->
	function
	| `Method (name, jname, (args, ret as sigt))		->
		let mid = add_global (`Method (jname, sigt)) in
		[ meth_impl name args
			(fun body -> [%expr (fun obj -> [%e body])])
			(ret.call mid) ]

	| `Method_static (name, jname, (args, ret as sigt))	->
		let mid = add_global (`Method_static (jname, sigt)) in
		[ meth_impl name args (wrap_no_args args) (ret.call_static mid) ]

	| `Field (name, jname, ti, mut)			->
		let fid = add_global (`Field (jname, ti)) in
		field_impl name mut
			[%expr (fun obj -> [%e ti.read_field fid])]
			[%expr (fun obj v -> [%e ti.write_field fid])]

	| `Field_static (name, jname, ti, mut)	->
		let fid = add_global (`Field_static (jname, ti)) in
		field_impl name mut
			[%expr (fun () -> [%e ti.read_field_static fid])]
			[%expr (fun v -> [%e ti.write_field_static fid])]

	| `Constructor (name, args)				->
		let cid = add_global (`Constructor args) in
		[ meth_impl name args (wrap_no_args args)
			[%expr of_obj_unsafe (Java.new_ __cls [%e mk_ident [ cid ]])] ]

(* Generates implementation *)
let class_impl path_name fields =
	let globals, add_global =
		let globals, count = ref [], ref 0 in
		globals, fun g ->
			let id = Printf.sprintf "__%d" !count in
			incr count;
			globals := (id, g) :: !globals;
			id
	in

	let items = List.fold_right (fun field items ->
		impl_item add_global field @ items
	) fields [] in

	let items = List.fold_left (fun items (id, g) ->
		mk_let id (global g) :: items
	) items !globals in

	let class_name = mk_cstr path_name in
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

(* Module sigt and impl *)
let class_ class_name path_name fields =
	let impl = class_impl path_name fields
	and sigt = class_sigt fields in
	let mn = String.capitalize_ascii class_name in
	Mb.mk (mk_loc mn) (Mod.constraint_ impl sigt)
