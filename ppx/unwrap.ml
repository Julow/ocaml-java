open Parsetree
open Ast_helper
open Longident
open Asttypes
open Ast_tools

(** Decode a class declaration node
	Raising a location error on syntax error
	(see `class_` below) *)

(** Unwrap a method type
	Returns the tuple (args core_type list, return core_type) *)
let rec method_type =
	function
	| [%type: [%t? lhs] -> [%t? rhs]]	->
		let args, ret = method_type rhs in
		lhs :: args, ret
	| t									-> [], t

(** Unwrap a class field
	Returns one of
		`Method (name, java_name, method_type)
		`Method_static ..
		`Field (name, java_name, core_type)
		`Field_static ..
		`Constructor (name, args core_type list)
	Raises a location error on syntax errors *)
let class_field =
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
			let static = is_static pcf_attributes in
			[], [ `Method (name, jname, method_type mtype, static) ]
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
			let static = is_static pcf_attributes in
			[], [ `Field (name, jname, ftype, mut = Mutable, static) ]
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
		begin match method_type ctype with
		| args, { ptyp_desc = Ptyp_any } -> [], [ `Constructor (name, args) ]
		| _ -> Location.raise_errorf ~loc "Constructor must returns `_'"
		end
	| { pcf_desc = Pcf_initializer { pexp_desc = Pexp_constraint (
			{ pexp_loc = loc }, _) } }	->
		Location.raise_errorf ~loc "Expecting constructor name"
	| { pcf_desc = Pcf_initializer { pexp_loc = loc } }	->
		Location.raise_errorf ~loc "Expecting constructor"

	| { pcf_desc = Pcf_inherit (Fresh, { pcl_desc =
			Pcl_constr ({ txt = id }, []) }, None) } ->
		[ id ], []
	| { pcf_desc = Pcf_inherit (Fresh, { pcl_loc = loc }, None) } ->
		Location.raise_errorf ~loc "Expecting class name"
	| { pcf_desc = Pcf_inherit (Fresh, _, Some { loc }) } ->
		Location.raise_errorf ~loc "Unsupported syntax"
	| { pcf_desc = Pcf_inherit (Override, _, _); pcf_loc = loc } ->
		Location.raise_errorf ~loc "Override inherit"

	| { pcf_loc = loc } -> Location.raise_errorf ~loc "Unsupported"

(** Unwrap the class_info node
	Returns the tuple (class_name, java_path, class_field list)
	Raises a location error on syntax errors *)
let class_ =
	function
	| {	pci_name = { txt = class_name };
		pci_expr = { pcl_desc = Pcl_fun (Nolabel, None,
				{ ppat_desc = Ppat_constant (Pconst_string (java_path, None)) },
				{ pcl_desc = Pcl_structure {
					pcstr_self = { ppat_desc = Ppat_any };
					pcstr_fields = fields } }) } } ->
		let supers, fields = List.fold_right (fun field (s, f) ->
			let s', f' = class_field field in
			s' @ s, f' @ f
		) fields ([], []) in
		class_name, java_path, supers, fields
	| { pci_expr = { pcl_desc = Pcl_fun (_, _, _, { pcl_desc = Pcl_structure {
				pcstr_self = { ppat_desc; ppat_loc = loc }
			}})} } when ppat_desc <> Ppat_any ->
		Location.raise_errorf ~loc "self is not allowed"
	| { pci_expr = { pcl_desc = Pcl_fun (_, _, { ppat_desc =
			Ppat_constant (Pconst_string _) }, { pcl_loc = loc }) } } ->
		Location.raise_errorf ~loc "Expecting object"
	| { pci_loc = loc }		->
		Location.raise_errorf ~loc "Expecting Java class path"
