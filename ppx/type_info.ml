open Parsetree
open Ast_tools

(** Represent a type that have convertions in ocaml-java
	Most expressions expect "obj", "id" and/or "cls" to be defined to
	the current object, the ID of the method/field and the current class
	`push` takes the name of the argument as parameter *)
type t = {
	sigt : expression;
	type_ : core_type;
	push : string -> expression;
	call : expression;
	call_static : expression;
	read_field : expression;
	write_field : expression;
	read_field_static : expression;
	write_field_static : expression
}

(** Create a type_info
	`conv_to`/`conv_of` are applied to the argument/return value
		of call, read and write calls *)
let create ~push ~call ~call_static ~read_field ~write_field
	~read_field_static ~write_field_static sigt type_ conv_to conv_of =
	let push arg = [%expr [%e push] ([%e conv_to (mk_ident [ arg ])])] in
	{ sigt; type_; push;
		call = conv_of [%expr [%e call] obj id];
		call_static = conv_of [%expr [%e call_static] cls id];
		read_field = conv_of [%expr [%e read_field] obj id];
		write_field = [%expr [%e write_field] obj id [%e conv_to [%expr v]]];
		read_field_static = conv_of [%expr [%e read_field_static] cls id];
		write_field_static =
			[%expr [%e write_field_static] cls id [%e conv_to [%expr v]]] }

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
