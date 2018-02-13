open Parsetree
open Ast_tools

(* Most expressions expect `obj`, `__cls` and `to_obj` to be defined *)
type t = {
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

(** Create a type_info
	`conv_to`/`conv_of` are applied to the argument/return value
		of call, read and write calls *)
let create ~push ~call ~call_static ~read_field ~write_field
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

(** Concat a list of type_info by signatures *)
let rec concat_sigt =
	function
	| [ arg ]	-> [%expr [%e arg.sigt]]
	| arg :: tl	-> [%expr [%e arg.sigt] ^ [%e concat_sigt tl]]
	| []		-> mk_cstr ""

(** Returns the method signature *)
let meth_sigt (args, ret) =
	let ret = match ret with
		| `Void		-> mk_cstr "V"
		| `Ret ti	-> ti.sigt
	in
	[%expr "(" ^ [%e concat_sigt args] ^ ")" ^ [%e ret]]
