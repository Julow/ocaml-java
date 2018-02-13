open Ast_mapper
open Ast_helper
open Parsetree
open Asttypes

let structure_item mapper =
	function
	| { pstr_desc = Pstr_extension (({ txt = "java" }, PStr [
			{ pstr_desc = Pstr_class classes }
		]), _) }	->
		let classes = List.map Unwrap.class_ classes in
		let near_classes = List.map (fun (n, p, _) -> n, p) classes in
		let gen (name, java_path, unwrap) =
			Gen.class_ name java_path (unwrap near_classes)
		in
		begin match List.map gen classes with
		| [ cls ]	-> Str.module_ cls
		| classes	-> Str.rec_module classes
		end
	| item			-> default_mapper.structure_item mapper item

let mapper _ = { default_mapper with structure_item }

let () = register "ocaml-java-ppx" mapper
