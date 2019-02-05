exception Not_found
exception End_of_file
exception Failure of string
exception Invalid_argument of string

external raise : = "_raise"

let invalid_arg x = raise (Invalid_argument x)
let failwith x = raise (Failure x)

let ignore _ = ()
let succ x = x + 1
let pred x = x - 1

type bool = false | true
type ref = { mutable contents : 'a }
type result = Ok of 'a | Error of 'b
type list = Null | Cons of 'a * 'a list

module Obj = struct
  let repr x = x
  let magic x = x
  external is_block : = "caml_obj_is_block"
  external new_block : = "caml_obj_block"
  external tag : = "caml_obj_tag"
  external set_tag : = "caml_obj_set_tag"
  external size : = "caml_obj_size"
  external field : = "caml_obj_field"
  external set_field : = "caml_obj_set_field"
  external is_int : = "caml_obj_is_int"
  external string_tag : = "(Val_long(String_tag))"
end
let lazy x = x
module Lazy = struct let force x = x end

let int_of_char x = x
let char_of_int x = x

module List = struct
  let hd x = match x with [] -> assert false | a :: b -> a
  let tl x = match x with [] -> assert false | a :: b -> b
  let rec filter f l = match l with [] -> [] | x :: l -> if f x then x :: filter f l else filter f l
  let rec map f l = match l with [] -> [] | x :: l -> f x :: map f l
  let rec map1 f a l = match l with [] -> [] | x :: l -> f a x :: map1 f a l
  let rec iter1 f a l = match l with [] -> () | x :: l -> f a x; iter1 f a l
  let rec iteri_loop f i l = match l with [] -> () | x :: l -> f i x; iteri_loop f (i + 1) l
  let iteri f l = iteri_loop f 0 l
  let rec iteri1_loop f a i l = match l with [] -> () | x :: l -> f a i x; iteri1_loop f a (i + 1) l
  let iteri1 f a l = iteri1_loop f a 0 l
  let rec fold_left f acc l = match l with [] -> acc | x :: l -> fold_left f (f acc x) l
  let rec fold_right f l acc = match l with [] -> acc | x :: l -> f x (fold_right f l acc)
  let rec fold_left1 f arg acc l = match l with [] -> acc | x :: l -> fold_left1 f arg (f arg acc x) l
  let rec fold_right1 f arg l acc = match l with [] -> acc | x :: l -> f arg x (fold_right1 f arg l acc)
  let rec rev_append l r = match l with [] -> r | x :: l -> rev_append l (x :: r)
  let rev l = rev_append l []
  let rec mem x l = match l with [] -> false | y :: l -> if x = y then true else mem x l
  let rec length l = match l with [] -> 0 | x :: l -> 1 + length l
  let rec find f l = match l with [] -> raise Not_found | x :: l -> if f x then x else find f l
  let rec find1 f a l = match l with [] -> raise Not_found | x :: l -> if f a x then x else find1 f a l

  let rec assoc x l = match l with | [] -> raise Not_found | a :: l -> let (u, v) = a in if x = u then v else assoc x l
  let rec mem_assoc x l = match l with | [] -> false | a :: l -> let (u, v) = a in if x = u then true else mem_assoc x l
end

module Hashtbl = struct
  let find t x = List.assoc x t
  let mem t x = List.mem_assoc x t
end

module Bytes = struct
  external blit : = "caml_blit_bytes"
  external unsafe_blit : = "caml_blit_bytes"
  external blit_string : = "caml_blit_string"
  external create : = "caml_create_bytes"
  external get : = "caml_bytes_get"
  external set : = "caml_bytes_set"
  external unsafe_get : = "caml_bytes_get"
  external unsafe_set : = "caml_bytes_set"
  external unsafe_of_string : = "caml_bytes_of_string"
  external unsafe_to_string : = "caml_string_of_bytes"
  external length : = "caml_ml_bytes_length"
  external unsafe_fill : = "caml_fill_bytes"

  let copy s =
    let len = length s in
    let r = create len in
    unsafe_blit s 0 r 0 len;
    r

  let to_string b = unsafe_to_string (copy b)
  let of_string s = copy (unsafe_of_string s)

  let sub s ofs len =
    if ofs < 0 || len < 0 || ofs > length s - len
    then invalid_arg "String.sub / Bytes.sub"
    else begin
      let r = create len in
      unsafe_blit s ofs r 0 len;
      r
    end

  let sub_string b ofs len = unsafe_to_string (sub b ofs len)
end

module String = struct
  external length : = "caml_ml_string_length"
  external unsafe_get : = "caml_string_get"
  external blit : = "caml_blit_string"

  let sub s ofs len =
    Bytes.unsafe_to_string (Bytes.sub (Bytes.unsafe_of_string s) ofs len)

  let rec index_rec s lim i c =
    if i >= lim then raise Not_found else
    if unsafe_get s i = c then i else index_rec s lim (i + 1) c

  let index_from s i c =
    let l = length s in
    if i < 0 || i > l then invalid_arg "String.index_from / Bytes.index_from" else
      index_rec s l i c
end

external string_get : = "caml_string_get"
let string_concat s1 s2 =
  let r = Bytes.create (String.length s1 + String.length s2) in
  Bytes.blit_string s1 0 r 0 (String.length s1);
  Bytes.blit_string s2 0 r (String.length s1) (String.length s2);
  Bytes.unsafe_to_string r

module Char = struct let code x = x let chr x = x let unsafe_chr x = x end
module Uchar = struct let unsafe_of_int x = x let to_int x = x let is_valid x = true end

let rec list_concat l1 l2 = match l1 with [] -> l2 | x :: l1 -> x :: list_concat l1 l2

external compare : = "caml_compare"
external eq : = "caml_equal"
external neq : = "caml_notequal"
external lessequal : = "caml_lessequal"
external lessthan : = "caml_lessthan"

let ref x = { contents = x }
let ref_get x = x.contents
let ref_set x y = x.contents <- y
let incr x = ref_set x (ref_get x + 1)
let decr x = ref_set x (ref_get x - 1)
let not x = 1 - x

module Array = struct
  external blit : = "caml_array_blit"
  external make : = "caml_make_vect"
  external unsafe_set : = "caml_array_set"
  external length : = "caml_obj_size"
  external empty_array : = "(Atom(0))"

  let rec fill_loop a x y v = if x >= y then () else begin unsafe_set a x v; fill_loop a (x + 1) y v end
  let fill a ofs len v =
    fill_loop a ofs (ofs + len) v
  
  let rec of_list_loop a i l = match l with
    | [] -> a
    | hd :: tl -> unsafe_set a i hd; of_list_loop a (i + 1) tl
  let of_list l = match l with
    | [] -> empty_array
    | hd :: tl -> let a = make (List.length l) in of_list_loop a 1 tl
end

module Hashtbl = struct
  external seeded_hash_param : = "caml_hash"
  let hash x = seeded_hash_param 10 100 0 x
end

external array_get : = "caml_array_get"
external array_set : = "caml_array_set"
external int_of_string : = "caml_int_of_string"

external unsafe_input : = "caml_ml_input"

let input ic s ofs len =
  if ofs < 0 || len < 0 || ofs > Bytes.length s - len
  then invalid_arg "input"
  else unsafe_input ic s ofs len

external unsafe_output : = "caml_ml_output_bytes"

let output oc s ofs len =
  if ofs < 0 || len < 0 || ofs > Bytes.length s - len
  then invalid_arg "output"
  else unsafe_output oc s ofs len

external open_descriptor_out : int -> out_channel
                             = "caml_ml_open_descriptor_out"
external open_descriptor_in : int -> in_channel = "caml_ml_open_descriptor_in"
type open_flag =
    Open_rdonly | Open_wronly | Open_append
  | Open_creat | Open_trunc | Open_excl
  | Open_binary | Open_text | Open_nonblock

external open_desc : string -> open_flag list -> int -> int = "caml_sys_open"

let open_in_gen mode perm name =
  let c = open_descriptor_in(open_desc name mode perm) in
  set_in_channel_name c name;
  c

let open_in name =
  open_in_gen [Open_rdonly; Open_text] 0 name

external close_in : in_channel -> unit = "caml_ml_close_channel"

external set_in_channel_name: in_channel -> string -> unit =
  "caml_ml_set_channel_name"

module Sys = struct
  type backend_type =
  | Native
  | Bytecode
  | Other of string
end
