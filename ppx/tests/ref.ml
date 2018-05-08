module A :
  sig
    type c = [ `a_A ]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    val __class_name : unit -> string
    val __class : unit -> Java.jclass
    val of_obj : 'a Java.obj -> t
    val a : _ t' -> unit
  end =
  struct
    type c = [ `a_A ]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    let __class_name () = "a/A"
    let __cls : Jclass.t array = [|(Obj.magic 0);(Obj.magic 0)|]
    let __class () =
      let cls = Array.unsafe_get __cls 0 in
      if cls == (Obj.magic 0)
      then
        let cls = Jclass.find_class "a/A" in
        (Array.unsafe_set __cls 0 cls; cls)
      else cls
    external of_obj_unsafe : 'a Java.obj -> t = "%identity"
    let of_obj obj =
      if Java.instanceof obj (__class ())
      then of_obj_unsafe obj
      else failwith "of_obj"
    let a obj =
      let id =
        let id = Array.unsafe_get __cls 1 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_meth (__class ()) "a" "()V" in
          (Array.unsafe_set __cls 1 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.call_void obj id
  end 
module Test :
  sig
    type c = [ `test_Test  | A.c | B.c | C.c]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    val __class_name : unit -> string
    val __class : unit -> Java.jclass
    val of_obj : 'a Java.obj -> t
    val get'a : _ t' -> A.t
    val get'b : _ t' -> test option option
    val set'b : _ t' -> test option option -> unit
    val get'c : unit -> int
    val set'c : int -> unit
    val a : _ t' -> _ A.t' -> A.t
    val b : _ t' -> unit
    val c :
      _ t' ->
        int ->
          bool ->
            int ->
              int ->
                Int32.t ->
                  Int64.t ->
                    char ->
                      float ->
                        float ->
                          string ->
                            string option ->
                              ((a * b) -> c) ->
                                (a b c * [> `D of e ]) option -> unit
    val d : _ t' -> _ t' -> t
    val f : _ t' -> unit
    val g : _ Abc.Def.t' -> _ Ghi.Jkl.Mno.t' -> Pqr.t
    val h :
      _ t' ->
        int Jarray.t -> int Jarray.t Jarray.t option -> int Java.obj Jarray.t
    val i :
      _ t' ->
        int array Jarray.jvalue Jarray.t Jarray.t Jarray.t Jarray.t option ->
          Jarray.jbyte Jarray.t ->
            Jarray.jshort Jarray.t option -> Jarray.jdouble Jarray.t Jarray.t
    val j : _ t' -> _ Java.obj -> int
    val create_default : unit -> t
    val create : _ A.t' -> test -> int -> t
  end =
  struct
    type c = [ `test_Test  | A.c | B.c | C.c]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    let __class_name () = "test/Test"
    let __cls : Jclass.t array =
      [|(Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(
        Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(
        Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(Obj.magic 0);(Obj.magic 0)|]
    let __class () =
      let cls = Array.unsafe_get __cls 0 in
      if cls == (Obj.magic 0)
      then
        let cls = Jclass.find_class "test/Test" in
        (Array.unsafe_set __cls 0 cls; cls)
      else cls
    external of_obj_unsafe : 'a Java.obj -> t = "%identity"
    let of_obj obj =
      if Java.instanceof obj (__class ())
      then of_obj_unsafe obj
      else failwith "of_obj"
    let get'a obj =
      let id =
        let id = Array.unsafe_get __cls 14 in
        if id == (Obj.magic 0)
        then
          let id =
            Jclass.get_field (__class ()) "a"
              ("L" ^ ((A.__class_name ()) ^ ";")) in
          (Array.unsafe_set __cls 14 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.read_field_object obj id
    let get'b obj =
      let id =
        let id = Array.unsafe_get __cls 13 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_field (__class ()) "b" "Ljuloo/javacaml/Value;" in
          (Array.unsafe_set __cls 13 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.read_field_value_opt obj id
    let set'b obj v =
      let id =
        let id = Array.unsafe_get __cls 13 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_field (__class ()) "b" "Ljuloo/javacaml/Value;" in
          (Array.unsafe_set __cls 13 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.write_field_value_opt obj id v
    let get'c () =
      let id =
        let id = Array.unsafe_get __cls 12 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_field_static (__class ()) "c" "I" in
          (Array.unsafe_set __cls 12 (Obj.magic id); id)
        else Obj.magic id in
      let cls = Array.unsafe_get __cls 0 in
      Jcall.read_field_static_int cls id
    let set'c v =
      let id =
        let id = Array.unsafe_get __cls 12 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_field_static (__class ()) "c" "I" in
          (Array.unsafe_set __cls 12 (Obj.magic id); id)
        else Obj.magic id in
      let cls = Array.unsafe_get __cls 0 in
      Jcall.write_field_static_int cls id v
    let a obj x0 =
      Jcall.push_object x0;
      (let id =
         let id = Array.unsafe_get __cls 11 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_meth (__class ()) "a"
               ("(L" ^
                  ((A.__class_name ()) ^
                     (";)L" ^ ((A.__class_name ()) ^ ";")))) in
           (Array.unsafe_set __cls 11 (Obj.magic id); id)
         else Obj.magic id in
       Jcall.call_object obj id)
    let b obj =
      let id =
        let id = Array.unsafe_get __cls 10 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_meth (__class ()) "b" "()V" in
          (Array.unsafe_set __cls 10 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.call_void obj id
    let c obj x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 =
      Jcall.push_int x0;
      Jcall.push_bool x1;
      Jcall.push_byte x2;
      Jcall.push_short x3;
      Jcall.push_int32 x4;
      Jcall.push_long x5;
      Jcall.push_char x6;
      Jcall.push_float x7;
      Jcall.push_double x8;
      Jcall.push_string x9;
      Jcall.push_string_opt x10;
      Jcall.push_value x11;
      Jcall.push_value_opt x12;
      (let id =
         let id = Array.unsafe_get __cls 9 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_meth (__class ()) "c"
               "(IZBSIJCFDLjava/lang/String;Ljava/lang/String;Ljuloo/javacaml/Value;Ljuloo/javacaml/Value;)V" in
           (Array.unsafe_set __cls 9 (Obj.magic id); id)
         else Obj.magic id in
       Jcall.call_void obj id)
    let d obj x0 =
      Jcall.push_object x0;
      (let id =
         let id = Array.unsafe_get __cls 8 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_meth (__class ()) "d" "(Ltest/Test;)Ltest/Test;" in
           (Array.unsafe_set __cls 8 (Obj.magic id); id)
         else Obj.magic id in
       Jcall.call_object obj id)
    let f x0 =
      Jcall.push_object x0;
      (let id =
         let id = Array.unsafe_get __cls 7 in
         if id == (Obj.magic 0)
         then
           let id = Jclass.get_meth_static (__class ()) "f" "(Ltest/Test;)V" in
           (Array.unsafe_set __cls 7 (Obj.magic id); id)
         else Obj.magic id in
       let cls = Array.unsafe_get __cls 0 in Jcall.call_static_void cls id)
    let g x0 x1 =
      Jcall.push_object x0;
      Jcall.push_object x1;
      (let id =
         let id = Array.unsafe_get __cls 6 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_meth_static (__class ()) "g"
               ("(L" ^
                  ((Abc.Def.__class_name ()) ^
                     (";L" ^
                        ((Ghi.Jkl.Mno.__class_name ()) ^
                           (";)L" ^ ((Pqr.__class_name ()) ^ ";")))))) in
           (Array.unsafe_set __cls 6 (Obj.magic id); id)
         else Obj.magic id in
       let cls = Array.unsafe_get __cls 0 in Jcall.call_static_object cls id)
    let h obj x0 x1 =
      Jcall.push_array x0;
      Jcall.push_array_opt x1;
      (let id =
         let id = Array.unsafe_get __cls 5 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_meth (__class ()) "h" "([I[[I)[Ljava/lang/Object;" in
           (Array.unsafe_set __cls 5 (Obj.magic id); id)
         else Obj.magic id in
       Jcall.call_array obj id)
    let i obj x0 x1 x2 =
      Jcall.push_array_opt x0;
      Jcall.push_array x1;
      Jcall.push_array_opt x2;
      (let id =
         let id = Array.unsafe_get __cls 4 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_meth (__class ()) "i"
               "([[[[Ljuloo/javacaml/Value;[B[S)[[D" in
           (Array.unsafe_set __cls 4 (Obj.magic id); id)
         else Obj.magic id in
       Jcall.call_array obj id)
    let j obj x0 =
      Jcall.push_object x0;
      (let id =
         let id = Array.unsafe_get __cls 3 in
         if id == (Obj.magic 0)
         then
           let id = Jclass.get_meth (__class ()) "j" "(Ljava/lang/Object;)I" in
           (Array.unsafe_set __cls 3 (Obj.magic id); id)
         else Obj.magic id in
       Jcall.call_int obj id)
    let create_default () =
      let id =
        let id = Array.unsafe_get __cls 2 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_constructor (__class ()) "()V" in
          (Array.unsafe_set __cls 2 (Obj.magic id); id)
        else Obj.magic id in
      let cls = Array.unsafe_get __cls 0 in Jcall.new_ cls id
    let create x0 x1 x2 =
      Jcall.push_object x0;
      Jcall.push_value x1;
      Jcall.push_int x2;
      (let id =
         let id = Array.unsafe_get __cls 1 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_constructor (__class ())
               ("(L" ^ ((A.__class_name ()) ^ ";Ljuloo/javacaml/Value;I)V")) in
           (Array.unsafe_set __cls 1 (Obj.magic id); id)
         else Obj.magic id in
       let cls = Array.unsafe_get __cls 0 in Jcall.new_ cls id)
  end 
module rec
  String_builder:sig
                   type c = [ `java_lang_StringBuilder ]
                   type 'a t' = ([> c] as 'a) Java.obj
                   type t = c Java.obj
                   val __class_name : unit -> string
                   val __class : unit -> Java.jclass
                   val of_obj : 'a Java.obj -> t
                   val create : unit -> t
                   val to_string : _ t' -> Jstring.t
                 end =
  struct
    type c = [ `java_lang_StringBuilder ]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    let __class_name () = "java/lang/StringBuilder"
    let __cls : Jclass.t array =
      [|(Obj.magic 0);(Obj.magic 0);(Obj.magic 0)|]
    let __class () =
      let cls = Array.unsafe_get __cls 0 in
      if cls == (Obj.magic 0)
      then
        let cls = Jclass.find_class "java/lang/StringBuilder" in
        (Array.unsafe_set __cls 0 cls; cls)
      else cls
    external of_obj_unsafe : 'a Java.obj -> t = "%identity"
    let of_obj obj =
      if Java.instanceof obj (__class ())
      then of_obj_unsafe obj
      else failwith "of_obj"
    let create () =
      let id =
        let id = Array.unsafe_get __cls 2 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_constructor (__class ()) "()V" in
          (Array.unsafe_set __cls 2 (Obj.magic id); id)
        else Obj.magic id in
      let cls = Array.unsafe_get __cls 0 in Jcall.new_ cls id
    let to_string obj =
      let id =
        let id = Array.unsafe_get __cls 1 in
        if id == (Obj.magic 0)
        then
          let id =
            Jclass.get_meth (__class ()) "toString" "()Ljava/lang/String;" in
          (Array.unsafe_set __cls 1 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.call_object obj id
  end
 and
  Jstring:sig
            type c = [ `java_lang_String ]
            type 'a t' = ([> c] as 'a) Java.obj
            type t = c Java.obj
            val __class_name : unit -> string
            val __class : unit -> Java.jclass
            val of_obj : 'a Java.obj -> t
            val of_builder : _ String_builder.t' -> t
            val to_string : _ t' -> string
          end =
  struct
    type c = [ `java_lang_String ]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    let __class_name () = "java/lang/String"
    let __cls : Jclass.t array =
      [|(Obj.magic 0);(Obj.magic 0);(Obj.magic 0)|]
    let __class () =
      let cls = Array.unsafe_get __cls 0 in
      if cls == (Obj.magic 0)
      then
        let cls = Jclass.find_class "java/lang/String" in
        (Array.unsafe_set __cls 0 cls; cls)
      else cls
    external of_obj_unsafe : 'a Java.obj -> t = "%identity"
    let of_obj obj =
      if Java.instanceof obj (__class ())
      then of_obj_unsafe obj
      else failwith "of_obj"
    let of_builder x0 =
      Jcall.push_object x0;
      (let id =
         let id = Array.unsafe_get __cls 2 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_constructor (__class ())
               "(Ljava/lang/StringBuilder;)V" in
           (Array.unsafe_set __cls 2 (Obj.magic id); id)
         else Obj.magic id in
       let cls = Array.unsafe_get __cls 0 in Jcall.new_ cls id)
    let to_string obj =
      let id =
        let id = Array.unsafe_get __cls 1 in
        if id == (Obj.magic 0)
        then
          let id =
            Jclass.get_meth (__class ()) "toString" "()Ljava/lang/String;" in
          (Array.unsafe_set __cls 1 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.call_string obj id
  end
module Jfloat :
  sig
    type c = [ `java_lang_Float ]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    val __class_name : unit -> string
    val __class : unit -> Java.jclass
    val of_obj : 'a Java.obj -> t
    val float_value : _ t' -> float
    val of_string : _ Jstring.t' -> t
  end =
  struct
    type c = [ `java_lang_Float ]
    type 'a t' = ([> c] as 'a) Java.obj
    type t = c Java.obj
    let __class_name () = "java/lang/Float"
    let __cls : Jclass.t array =
      [|(Obj.magic 0);(Obj.magic 0);(Obj.magic 0)|]
    let __class () =
      let cls = Array.unsafe_get __cls 0 in
      if cls == (Obj.magic 0)
      then
        let cls = Jclass.find_class "java/lang/Float" in
        (Array.unsafe_set __cls 0 cls; cls)
      else cls
    external of_obj_unsafe : 'a Java.obj -> t = "%identity"
    let of_obj obj =
      if Java.instanceof obj (__class ())
      then of_obj_unsafe obj
      else failwith "of_obj"
    let float_value obj =
      let id =
        let id = Array.unsafe_get __cls 2 in
        if id == (Obj.magic 0)
        then
          let id = Jclass.get_meth (__class ()) "floatValue" "()F" in
          (Array.unsafe_set __cls 2 (Obj.magic id); id)
        else Obj.magic id in
      Jcall.call_float obj id
    let of_string x0 =
      Jcall.push_object x0;
      (let id =
         let id = Array.unsafe_get __cls 1 in
         if id == (Obj.magic 0)
         then
           let id =
             Jclass.get_meth_static (__class ()) "valueOf"
               ("(L" ^ ((Jstring.__class_name ()) ^ ";)Ljava/lang/Float;")) in
           (Array.unsafe_set __cls 1 (Obj.magic id); id)
         else Obj.magic id in
       let cls = Array.unsafe_get __cls 0 in Jcall.call_static_object cls id)
  end 
