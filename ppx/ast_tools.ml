open Ast_mapper
open Ast_helper
open Parsetree
open Asttypes
open Longident

let mk_loc txt = { txt; loc = !default_loc }

(* Module path *)
let mk_ident =
	let rec ident acc =
		function
		| l :: r	-> ident (Ldot (acc, l)) r
		| []		-> acc
	in
	function
	| l :: r	-> Exp.ident (mk_loc (ident (Lident l) r))
	| []		-> assert false

(* l.r *)
let mk_dot l r = Exp.ident (mk_loc (Ldot (l, r)))

(* Sequence (;) from a string *)
let rec mk_sequence =
	function
	| exp :: []	-> exp
	| exp :: tl	-> Exp.sequence exp (mk_sequence tl)
	| []		-> assert false

(* [let id = expr] *)
let mk_let id expr = [%stri let [%p Pat.var (mk_loc id)] = [%e expr]]
(* [val id : type_] *)
let mk_val id type_ = Sig.value (Val.mk (mk_loc id) type_)

(* Constant string *)
let mk_cstr s = Exp.constant (Const.string s)

(* [fun args.. -> body] *)
let mk_fun args body =
	let inc arg body = Exp.fun_ Nolabel None (Pat.var (mk_loc arg)) body in
	List.fold_right inc args body

(* [args.. -> t] *)
let mk_arrow args ret =
	let inc arg arrow = [%type: [%t arg] -> [%t arrow]] in
	List.fold_right inc args ret

(* Simplify string concatenation between constant or empty strings *)
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
