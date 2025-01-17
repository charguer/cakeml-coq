Require Import CakeSem.CakeAST.
Require Import CakeSem.Namespace.
Require Import CakeSem.ffi.FFI.
Require Import CakeSem.Word.
Require Import CakeSem.Utils.

Import Arith.
Require Import Ascii.
Import Bool.Sumbool.
Require Import List.
Require Import Lists.ListDec.
Import ListNotations.
Require Strings.String.
Require PeanoNat.
Definition eqb := PeanoNat.Nat.eqb.
(* Require Import Strings.Ascii. *)
Require Import ZArith.

Open Scope string_scope.



Inductive stamp : Set :=
| TypeStamp : conN -> nat -> stamp
| ExnStamp : nat -> stamp.

Theorem stamp_eq_dec : forall x y : stamp, {x = y} + {x <> y}.
  repeat decide equality. Qed.
Hint Resolve stamp_eq_dec : DecidableEquality.


Record sem_env (V : Type) := {
                              sev : namespace modN varN V;
                              sec : namespace modN conN (nat * stamp)
                              }.

Arguments sev {V} _.
Arguments sec {V} _.

Theorem sem_env_eq_dec : forall (V : Type) (s0 s1 : sem_env V),
    (forall (v0 v1 : V), {v0 = v1} + {v0 <> v1}) -> {s0 = s1} + {s0 <> s1}.
Proof.
  decide equality; apply namespace_eq_dec; try (auto with DecidableEquality).
  decide equality; auto with DecidableEquality.
Qed.
Hint Resolve sem_env_eq_dec : DecidableEquality.

(* Values *)
Unset Elimination Schemes.
Inductive val : Type :=
| Litv : lit -> val
| Conv : option stamp -> list val -> val
| Closure : sem_env val -> varN -> exp -> val
| Recclosure : sem_env val -> list (varN * varN * exp) -> varN -> val
| Loc : nat -> val
| Vectorv : list val -> val.

Fixpoint val_rect (P : val -> Type)
         (H1 : forall (l : lit), P (Litv l))
         (H2 : forall (o : option stamp) (l : list val), Forall'' val P l -> P (Conv o l))
         (H3 : forall (s : sem_env val) (n : varN) (e : exp), Forall'' (ident modN varN * val) (fun p => P (snd p)) (sev s) -> P (Closure s n e))
         (H4 : forall (s : sem_env val) (l : list (varN * varN * exp)) (n : varN), Forall'' (ident modN varN * val) (fun p => P (snd p)) (sev s) ->
                                                                            P (Recclosure s l n))
         (H5 : forall (n : nat), P (Loc n))
         (H6 : forall (l : list val), Forall'' val P l -> P (Vectorv l))
         (v : val) : P v :=
  let val_rect' := val_rect P H1 H2 H3 H4 H5 H6 in
  match v with
  | Litv l => H1 l
  | Conv o l => let fix loop (l : list val) :=
                   match l with
                   | [] => Forall_nil'' val P
                   | h::t => Forall_cons'' val P h t (val_rect' h) (loop t)
                   end
               in
               H2 o l (loop l)
  | Closure s n e => let fix loop__ns (ls : namespace modN varN val) :=
                        match ls with
                          | [] => Forall_nil'' (ident modN varN * val) (fun p => P (snd p))
                          | ((i,v'))::ls' => Forall_cons'' (ident modN varN * val) (fun p => P (snd p))
                                                       (i,v') ls' (val_rect' v') (loop__ns ls')
                        end
                    in
                    H3 s n e (loop__ns (sev s))
  | Recclosure s l n => let fix loop__ns (ls : namespace modN varN val) :=
                           match ls with
                           | [] => Forall_nil'' (ident modN varN * val) (fun p => P (snd p))
                           | ((i,v'))::ls' => Forall_cons'' (ident modN varN * val) (fun p => P (snd p))
                                                         (i,v') ls' (val_rect' v') (loop__ns ls')
                           end
                       in
                       H4 s l n (loop__ns (sev s))
  | Loc n => H5 n
  | Vectorv l => let fix loop (l : list val) :=
                    match l with
                    | [] => Forall_nil'' val P
                    | h::t => Forall_cons'' val P h t (val_rect' h) (loop t)
                    end
                in
                H6 l (loop l)
  end.

Definition val_ind (P : val -> Prop) := val_rect P.
Definition val_rec (P : val -> Set) := val_rect P.

Theorem val_eq_dec : forall (v0 v1 : val), {v0 = v1} + {v0 <> v1}.
Proof.
  decide equality; auto with DecidableEquality.

  generalize dependent l0.
  induction X; destruct l0;
    try (left; reflexivity); try (right; discriminate).
  destruct (p v); destruct (IHX l0).
  rewrite e, e0; left; reflexivity.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.

  decide equality; auto with DecidableEquality.

  generalize dependent s0.
  assert (pair_nat_stamp_dec : forall (p p0: (nat * stamp)), {p = p0} + {p <> p0})
    by (decide equality; auto with DecidableEquality).

  induction s; destruct s0.
  destruct (namespace_eq_dec modN conN (nat * stamp) String.string_dec String.string_dec pair_nat_stamp_dec sec0 sec1).
  rewrite e1.
  simpl in X.
  generalize dependent sev1.
  induction X; destruct sev1;
    try (left; reflexivity); try (right; discriminate).
  destruct x; destruct p0.
  destruct (ident_eq_dec modN varN i i0); try (apply String.string_dec).
  rewrite e2.
  destruct (p v3).
  simpl in e3; rewrite e3.
  destruct (IHX sev1).
  inversion e4.
  left; reflexivity.
  right; intro con; inversion con. apply n0. rewrite H0. reflexivity.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.

  apply list_eq_dec.
  decide equality; try (apply exp_eq_dec).
  decide equality; try (apply String.string_dec).

  generalize dependent s0.
  assert (pair_nat_stamp_dec : forall (p p0: (nat * stamp)), {p = p0} + {p <> p0})
    by (decide equality; auto with DecidableEquality).

  induction s; destruct s0.
  destruct (namespace_eq_dec modN conN (nat * stamp) String.string_dec String.string_dec pair_nat_stamp_dec sec0 sec1).
  rewrite e.
  simpl in X.
  generalize dependent sev1.
  induction X; destruct sev1;
    try (left; reflexivity); try (right; discriminate).
  destruct x; destruct p0.
  destruct (ident_eq_dec modN varN i i0); try (apply String.string_dec).
  rewrite e0.
  destruct (p v3).
  simpl in e1; rewrite e1.
  destruct (IHX sev1).
  inversion e2.
  left; reflexivity.
  right; intro con; inversion con. apply n0. rewrite H0. reflexivity.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.

  generalize dependent l0.
  induction X; destruct l0;
    try (left; reflexivity); try (right; discriminate).
  destruct (IHX l0); destruct (p v).
  rewrite e, e0. left; reflexivity.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.
  right; intro con; inversion con; auto.
Qed.
Hint Resolve val_eq_dec : DecidableEquality.

Definition env_ctor := namespace modN conN (nat * stamp).
Definition env_val := namespace modN varN val.

Definition bind_stamp := ExnStamp 0.
Definition chr_stamp := ExnStamp 1.
Definition div_stamp := ExnStamp 2.
Definition subscript_stamp := ExnStamp 3.

Definition bind_exn_v := Conv (Some bind_stamp) [].
Definition chr_exn_v  := Conv (Some chr_stamp) [].
Definition div_exn_v  := Conv (Some div_stamp) [].
Definition sub_exn_v  := Conv (Some subscript_stamp) [].

Definition bool_type_num := 0.
Definition list_type_num := 1.

(* Result of evaluation *)
Inductive abort : Type :=
| Rtype_error : abort
| Rtimeout_error : abort
| Rffi_error : final_event -> abort.

Inductive error_result (A : Type) : Type :=
| Rraise : A -> error_result A
| Rabort : abort -> error_result A.

Arguments Rraise {A}.
Arguments Rabort {A}.

Inductive result (A : Type) (B : Type) : Type :=
| Rval : A -> result A B
| Rerr : error_result B -> result A B.

(* Inductive result (A B : Type) : Type := *)
(* | Rval : A -> result A B *)
(* | RraisedErr : B -> result A B *)
(* | RabortErr  : abort -> result A B. *)

Arguments Rval {A} {B}.
Arguments Rerr {A} {B}.

(* Stores *)
Inductive store_v (A : Type) : Type :=
(* Reference *)
| Refv : A -> store_v A
(* Byte array *)
| W8array : list word8 -> store_v A
(* Value array *)
| Varray : list A -> store_v A.

Arguments Refv {A}.
Arguments W8array {A}.
Arguments Varray {A}.

Definition store_v_same_type (A : Type) (v1 v2 : store_v A) : bool :=
  match v1, v2 with
  | Refv _, Refv _ => true
  | W8array _, W8array _ => true
  | Varray _, Varray _ => true
  | _, _ => false
  end.

(* The nth item in the list is the value at location n *)
Definition store (A : Type) := list (store_v A).

Definition emptyStore (A : Type) : store A := [].

Definition store_lookup {A : Type} (n : nat) (st : store A) := nth_error st n.

Definition store_alloc {A : Type} (v : store_v A) (st : store A) : (store A * nat) :=
  (st ++ [v], length st).

Definition update {A : Type} (n : nat) (v : A)  (st : list A) : list A :=
  (firstn n st ++ [v] ++ skipn (n+1) st).

Fixpoint store_assign {A : Type} (n : nat) (v : store_v A) (st : store A)
  : option (store A) :=
  match nth_error st n with
  | Some v' => if store_v_same_type A v' v
              then Some (update n v st)
              else None
  | _ => None
  end.

Record state (A : Type) :=
  {
    clock : nat;
    refs : store val;
    ffi : ffi_state A;
    next_type_stamp : nat;
    next_exn_stamp : nat
  }.

Arguments clock {A} _.
Arguments refs {A} _.
Arguments ffi {A} _.
Arguments next_type_stamp {A} _.
Arguments next_exn_stamp {A} _.
Arguments refs {A} _.

(* Other primitives *)
Definition do_con_check (cenv : env_ctor)
           (n_opt : option (ident modN conN))
           (l : nat) : bool :=
  match n_opt with
  | None => true
  | Some n => match nsLookup n cenv with
             | None => false
             | Some (l',_) => extract_bool (eq_nat_dec l l')
             end
  end.

Definition build_conv (envC : env_ctor) (cn : option (ident modN conN))
           (vs : list val) : option val :=
  match cn with
  | None => Some (Conv None vs)
  | Some id => match nsLookup id envC with
              | None => None
              | Some (len,stamp) => Some (Conv (Some stamp) vs)
              end
  end.

Definition lit_same_type (l1 l2 : lit) : bool :=
  match l1, l2 with
    | IntLit _, IntLit _ => true
    | CharLit _, CharLit _ => true
    | StrLit _, StrLit _ => true
    | Word8Lit _, Word8Lit _ => true
    | Word64Lit _, Word64Lit _ => true
    | _, _ => false
  end.

Inductive match_result (A : Type) : Type :=
  | No_match : match_result A
  | Match_type_error : match_result A
  | Match : A -> match_result A.

Arguments No_match {A}.
Arguments Match_type_error {A}.
Arguments Match {A}.

(* TODO : Prop-ertize it *)
Definition same_type (s1 s2 : stamp) : bool :=
  match s1, s2 with
  | TypeStamp _ n1, TypeStamp _ n2 => extract_bool (eq_nat_dec n1 n2)
  | ExnStamp _, ExnStamp _ => true
  | _, _ => false
  end.

Definition same_ctor (s1 s2 : stamp) : bool := extract_bool (stamp_eq_dec s1 s2).

Definition ctor_same_type (c1 c2 : option stamp) : bool :=
  match c1, c2 with
    | None, None => true
    | Some stamp1, Some stamp2 => same_type stamp1 stamp2
    | _, _ => false
end.

(* A big-step pattern matcher.  If the value matches the pattern, return an
 * environment with the pattern variables bound to the corresponding sub-terms
 * of the value; this environment extends the environment given as an argument.
 * No_match is returned when there is no match, but any constructors
 * encountered in determining the match failure are applied to the correct
 * number of arguments, and constructors in corresponding positions in the
 * pattern and value come from the same type.  Match_type_error is returned
 * when one of these conditions is violated *)
Fixpoint pmatch (envC : env_ctor) (s : store val) (p : pat) (v : val)
         (env : alist varN val) : match_result (alist varN val) :=
  let fix pmatch_list (envC : env_ctor) (s : store val) (ps : list pat)
          (vs : list val) (env : alist varN val ) : match_result (alist varN val) :=
      match ps, vs with
      | [], [] => Match env
      | p::ps', v'::vs' =>
        (* Another way to do it (I THINK?) *)
        (* match pmatch envC s p v' env as res with
         * | Match env' => pmatch_list envC s ps' vs' env'
         * | _ => res
         * end *)
        match pmatch envC s p v' env with
        | No_match => No_match
        | Match_type_error => Match_type_error
        | Match env' => pmatch_list envC s ps' vs' env'
        end
      | _, _ => Match_type_error
      end
  in
  match p, v with
  | Pany, v' => Match env
  | Pvar x, v' => Match ((x,v')::env)
  | Plit l, Litv l' => if lit_eq_dec l l'
                      then Match env
                      else if lit_same_type l l'
                           then No_match
                           else Match_type_error
  | Pcon (Some n) ps, Conv (Some stamp') vs =>
    match  nsLookup n envC with
    | Some (l, stamp) => if andb (same_type stamp stamp')
                                (eqb (length ps) l)
                        then if same_ctor stamp stamp'
                             then if (eqb (length ps) l)
                                  then pmatch_list envC s ps vs env
                                  else Match_type_error
                             else No_match
                        else Match_type_error
    | _ => Match_type_error
    end
  | Pcon None ps, Conv None vs => pmatch_list envC s ps vs env
  (* I think this is just as fast? Actually...
   * maybe not though due to extra stuff happening on matches *)
  (* ORIG: *)
  (* if eqb (length ps) (length vs) *)
  (* then pmatch_list envC s ps vs env *)
  (* else Match_type_error *)
  | Pref p, Loc lnum => match store_lookup lnum s with
                       | Some (Refv v) => pmatch envC s p v env
                       | Some _ => Match_type_error
                       | None => Match_type_error
                       end
  | Ptannot p t, val' => pmatch envC s p val' env
  | _, _ => Match_type_error
  end.

Definition build_rec_env (funs : list (varN * varN * exp)) (cl_env : sem_env val)
           (add_to_env : env_val) : env_val :=
  fold_right (fun trip env' => match trip with
                          (f,x,e) => nsBind f (Recclosure cl_env funs f) env'
                        end)
        add_to_env
        funs.

Fixpoint find_recfun {A B : Type} (n : varN) (funs : list (varN * A * B))
  : option (A * B) :=
  match funs with
  | [] => None
  | (f,x,e)::funs' => if String.string_dec f n
                    then Some (x,e)
                     else find_recfun n funs'
  end.

Inductive eq_result : Type :=
| Eq_val : bool -> eq_result
| Eq_type_error.

Theorem option_eq_dec : forall (A : Type) (A_dec : forall (a b : A), {a = b} + {a <> b})
                          (x y : option A), {x = y} + {x <> y}.
Proof. decide equality. Qed.

(* Here we can probably start Prop-ertizing *)
Fixpoint do_eq (e1 e2 : val) : eq_result :=
  let fix do_eq_list (el1 el2 : list val) : eq_result :=
      match el1, el2 with
      | [], [] => Eq_val true
      | v1::vs1, v2::vs2 => match do_eq v1 v2 with
                         | Eq_type_error => Eq_type_error
                         | Eq_val r => if negb r (* Why? *)
                                      then Eq_val false
                                      else do_eq_list vs1 vs2
                         end
      | _, _ => Eq_val false
      end
  in
  match e1, e2 with
  | Litv l1, Litv l2 => if lit_same_type l1 l2
                       then Eq_val (extract_bool
                                      (lit_eq_dec l1 l2))
                       else Eq_type_error
  | Loc l1, Loc l2 => Eq_val (extract_bool (eq_nat_dec l1 l2))
  | Conv cn1 vs1, Conv cn2 vs2 => if sumbool_and _ _ _ _
                                                (option_eq_dec _ stamp_eq_dec
                                                               cn1 cn2)
                                                (eq_nat_dec (length vs1)
                                                            (length vs2))
                                 then do_eq_list vs1 vs2
                                 else if ctor_same_type cn1 cn2
                                      then Eq_val false
                                      else Eq_type_error
  | Vectorv vs1, Vectorv vs2 => if eq_nat_dec (length vs1) (length vs2)
                               then do_eq_list vs1 vs2
                               else Eq_val false
  | Closure _ _ _, Closure _ _ _ => Eq_val true
  | Closure _ _ _, Recclosure _ _ _ => Eq_val true
  | Recclosure _ _ _, Closure _ _ _ => Eq_val true
  | Recclosure _ _ _, Recclosure _ _ _ => Eq_val true
  | _, _ => Eq_type_error
  end.

Fixpoint do_opapp (vs : list val) : option (sem_env val * exp) :=
  match vs with
  | (Closure env n e)::v::[] =>
    Some ({| sev := nsBind n v (sev env); sec := sec env |}, e)
  | (Recclosure env funs n)::v::[] =>
    if NoDup_dec String.string_dec
                 (List.map (fun p => match p with (f,x,e) => f end) funs)
    then match find_recfun n funs with
         | Some (n,e) => Some ({| sev := nsBind n v
                                               (build_rec_env funs env
                                                                  (sev env));
                                 sec := sec env
                              |}, e)
         | None => None
         end
    else None
  | _ => None
  end.

Fixpoint val_to_list (v : val) : option (list val) :=
  match v with
  | Conv (Some stamp) [] => if stamp_eq_dec stamp (TypeStamp "[]" list_type_num)
                           then Some []
                           else None
  | Conv (Some stamp) [v1;v2] => if stamp_eq_dec stamp
                                                (TypeStamp "::" list_type_num)
                                then match val_to_list v2 with
                                     | Some vs => Some (v1::vs)
                                     | None => None
                                     end
                                else None
  | _ => None
  end.

Fixpoint list_to_val (vs : list val) : val :=
  match vs with
  | [] => Conv (Some (TypeStamp "[]" list_type_num)) []
  | v'::vs' => Conv (Some (TypeStamp "::" list_type_num)) [v'; list_to_val vs']
  end.

Fixpoint val_to_char_list (v : val) : option (list char) :=
  match v with
  | Conv (Some stamp) [] => if stamp_eq_dec stamp (TypeStamp "[]" list_type_num)
                           then Some []
                           else None
  | Conv (Some stamp) [Litv (CharLit c); v'] =>
    if stamp_eq_dec stamp (TypeStamp "::" list_type_num)
    then match val_to_char_list v' with
         | Some cs => Some (c::cs)
         | None => None
         end
    else None
  | _ => None
  end.

Fixpoint vals_to_string (vs : list val) : option String.string :=
  match vs with
  | [] => Some ""
  | (Litv (StrLit s1))::vs' => match vals_to_string vs' with
                             | Some s2 => Some (String.append s1 s2)
                             | None => None
                             end
  | _ => None
  end.

Open Scope bool_scope.
Open Scope Z_scope.
Fixpoint copy_array {A : Type} (p : list A * Z) (len : Z)
         (op : option (list A * Z)) : option (list A) :=
  match p with (src,srcoff) =>
               if (srcoff <? 0) || (len <? 0) || (Zlength src <? srcoff + len)
               then None
               else let copied := List.firstn (Z.to_nat len)
                                              (List.skipn (Z.to_nat srcoff) src)
                    in match op with
                       | Some (dst,dstoff) =>
                         if (dstoff <? 0) || (Zlength dst <? dstoff + len)
                         then None
                         else Some (List.firstn
                                      (Z.to_nat dstoff)
                                      dst ++ copied ++
                                      List.skipn (Z.to_nat (dstoff + len)) dst)
                       | None => Some copied
                       end
  end.
Close Scope bool_scope.
Close Scope Z_scope.

Definition opn_lookup (op : opn) : Z -> Z -> Z :=
  match op with
  | Plus => Z.add
  | Minus =>  Z.sub
  | Times => Z.mul
  | Divide => Z.div
  | Modulo => Z.modulo
  end.

Definition opb_lookup (op : opb) : Z -> Z -> bool :=
  match op with
  | Lt => Z.ltb
  | Gt => Z.gtb
  | Leq => Z.leb
  | Geq => Z.geb
  end.

Definition opw8_lookup (op : opw) : word8 -> word8 -> word8 :=
  match op with
  | Andw => word_and
  | Orw  => word_or
  | Xorw => word_xor
  | Addw => word_add
  end 8. (* this is kinda bee essy *)

Definition opw64_lookup (op : opw) : word64 -> word64 -> word64 :=
  match op with
  | Andw => word_and
  | Orw  => word_or
  | Xorw  => word_xor
  | Addw  => word_add
  end 64.

(* TODO: FAKE *)
Definition shift8_lookup (op : CakeAST.shift) : word8 -> nat -> word8 :=
 fun w n => match op with
         | Lsl => id w
         | Lsr => id w
         | Asr => id w
         | Ror => id w
         end.

(* TODO: FAKE *)
Definition shift64_lookup (op : CakeAST.shift) : word64 -> nat -> word64 :=
  fun w n => match op with
          | Lsl => id w
          | Lsr => id w
          | Asr => id w
          | Ror => id w
          end.

Definition Boolv (b : bool) : val :=
  if b
  then Conv (Some (TypeStamp "True"  bool_type_num)) []
  else Conv (Some (TypeStamp "False" bool_type_num)) [].

Inductive exp_or_val : Type :=
| Exp : exp -> exp_or_val
| Val : val -> exp_or_val.

Definition store_ffi (ffi' : Type) (V : Type) := (store V * ffi_state ffi')%type.

Open Scope bool_scope.
Require ZArith.Zdigits.
Fixpoint do_app (ffi' : Type) (st : store_ffi ffi' val) (o : op) (vs : list val)
  : option (store_ffi ffi' val * result val val) :=
  let natFromInteger  :=
      (fun n : nat => let fix helper (n' : nat ) (z : Z) : nat :=
                     match n' with
                     | O => O
                     | S n'' =>
                       2 ^ n' * (Z.to_nat (Zdigits.bit_value
                                            (Z.testbit (Z.of_nat n'') z)))
                           + (helper n'' z)
                     end
                 in helper n)
  in
  let word8FromInteger  := fun i : Z => nat_to_word 8 (natFromInteger 8 i)%nat  in
  let word64FromInteger := fun i : Z => nat_to_word 64 (natFromInteger 64%nat i) in
  match st with
    (s, t) =>
    match o, vs with
    | ListAppend, [x1;x2] =>
      match val_to_list x1, val_to_list x2 with
      | Some xs, Some ys =>
        Some ((s,t), Rval (list_to_val (xs ++ ys)))
      | _, _ => None
      end
    | Opn o', [Litv (IntLit n1); Litv (IntLit n2)] =>
      if sumbool_and _ _ _ _
                     (Z.eq_dec n2 0)
                     (sumbool_or _ _ _ _
                                 (opn_eq_dec o' Divide)
                                 (opn_eq_dec o' Modulo))
      then Some ((s,t), Rerr (Rraise div_exn_v))
      else Some ((s,t), Rval (Litv (IntLit (opn_lookup o' n1 n2))))
    | Opb o', [Litv (IntLit n1); Litv (IntLit n2)] =>
      Some ((s,t), Rval (Boolv (opb_lookup o' n1 n2)))
    | Opw W8 o', [Litv (Word8Lit w1); Litv (Word8Lit w2)] =>
      Some ((s,t), Rval (Litv (Word8Lit (opw8_lookup o' w1 w2))))
    | Opw W64 o', [Litv (Word64Lit w1); Litv (Word64Lit w2)] =>
      Some ((s,t), Rval (Litv (Word64Lit (opw64_lookup o' w1 w2))))
    (* | FP_bop bop, [Litv (Word64Lit w1); Litv (Word64Lit w2)] => *)
    (*     Some ((s,t),Rval (Litv (Word64Lit (fp_bop bop w1 w2)))) *)
    (* | FP_uop uop, [Litv (Word64Lit w)] => *)
    (*   Some ((s,t),Rval (Litv (Word64Lit (fp_uop uop w)))) *)
    (* | FP_cmp cmp, [Litv (Word64Lit w1); Litv (Word64Lit w2)] => *)
    (*   Some ((s,t),Rval (Boolv (fp_cmp cmp w1 w2))) *)
    | Shift W8 o' n, [Litv (Word8Lit w)] =>
      Some ((s,t), Rval (Litv (Word8Lit (shift8_lookup o' w n))))
    | Shift W64 o' n, [Litv (Word64Lit w)] =>
      Some ((s,t), Rval (Litv (Word64Lit (shift64_lookup o' w n))))
    | Equality, [v1; v2] =>
      match do_eq v1 v2 with
      | Eq_type_error => None
      | Eq_val b => Some ((s,t), Rval (Boolv b))
      end
    | Opassign, [Loc lnum; v] =>
      match store_assign lnum (Refv v) s with
      | Some s' => Some ((s',t), Rval (Conv None []))
      | None => None
      end
    | Opref, [v] =>
      let (s',n) := store_alloc (Refv v) s in
      Some ((s',t), Rval (Loc n))
    | Opderef, [Loc n] =>
      match store_lookup n s with
      | Some (Refv v) => Some ((s,t), Rval v)
      | _ => None
      end
    | Aw8alloc, [Litv (IntLit n); Litv (Word8Lit w)] =>
      if (n <? 0)%Z then
        Some ((s,t), Rerr (Rraise sub_exn_v))
      else
        let (s',lnum) := store_alloc (W8array (List.repeat w (Z.to_nat n))) s
        in Some ((s',t), Rval (Loc lnum))
    | Aw8sub, [Loc lnum; Litv (IntLit i)] =>
      match store_lookup lnum s with
      | Some (W8array ws) =>
        if (i <? 0)%Z
        then Some ((s,t), Rerr (Rraise sub_exn_v))
        else
          let n := Z.to_nat i in
          match List.nth_error ws n with
          | None => Some ((s,t), Rerr (Rraise sub_exn_v))
          | Some n' => Some ((s,t), Rval (Litv (Word8Lit n')))
          end
      | _ => None
      end
    | Aw8length, [Loc n] =>
      match store_lookup n s with
      | Some (W8array ws) => Some ((s,t), Rval (Litv (IntLit (Zlength ws))))
      | _ => None
      end
    | Aw8update, [Loc lnum; Litv (IntLit i); Litv (Word8Lit w)] =>
      match store_lookup lnum s with
      | Some (W8array ws) =>
        if (i <? 0)%Z then
          Some ((s,t), Rerr (Rraise sub_exn_v))
        else
          let n := Z.to_nat i in
          if leb (List.length ws) n then
            Some ((s,t), Rerr (Rraise sub_exn_v))
          else
            match store_assign lnum (W8array (update n w ws)) s with
            | None => None
            | Some s' => Some ((s',t), Rval (Conv None []))
            end
      | _ => None
      end
    | WordFromInt W8, [Litv (IntLit i)] =>
      Some ((s,t), Rval (Litv (Word8Lit (word8FromInteger i))))
    | WordFromInt W64, [Litv (IntLit i)] =>
      Some ((s,t), Rval (Litv (Word64Lit (word64FromInteger i))))
    | WordToInt W8, [Litv (Word8Lit w)] =>
      Some ((s,t), Rval (Litv (IntLit (Z.of_nat (word_to_nat _ w)))))
    | WordToInt W64, [Litv (Word64Lit w)] =>
      Some ((s,t), Rval (Litv (IntLit (Z.of_nat (word_to_nat _ w)))))
    | CopyStrStr, [Litv (StrLit str); Litv (IntLit off); Litv (IntLit len)] =>
      Some ((s,t),
            match copy_array (string_to_list_char str,off) len None with
            | None => Rerr (Rraise sub_exn_v)
            | Some cs => Rval (Litv (StrLit (list_char_to_string cs)))
            end)
    | CopyStrAw8, [Litv (StrLit str); Litv (IntLit off); Litv (IntLit len);
                     Loc dst; Litv (IntLit dstoff)] =>
      match store_lookup dst s with
      | Some (W8array ws) =>
        match copy_array (string_to_list_char str, off) len
                         (Some (map word8_to_char ws, dstoff)) with
        | None => Some ((s,t), Rerr (Rraise sub_exn_v))
        | Some cs =>
          match store_assign dst (W8array (map char_to_word8 cs)) s with
          | Some s' =>  Some ((s',t), Rval (Conv None []))
          | _ => None
          end
        end
      | _ => None
      end
    | CopyAw8Str, [Loc src; Litv (IntLit off); Litv (IntLit len)] =>
      match store_lookup src s with
      | Some (W8array ws) =>
        Some ((s,t),
        match copy_array (ws,off) len None with
        | None => Rerr (Rraise sub_exn_v)
        | Some ws => Rval (Litv (StrLit( list_char_to_string
                                         (map word8_to_char ws))))
        end)
      | _ => None
      end
    | CopyAw8Aw8, [Loc src; Litv (IntLit off); Litv (IntLit len);
                     Loc dst; Litv (IntLit dstoff)] =>
      match store_lookup src s, store_lookup dst s with
      | Some (W8array ws), Some (W8array ds) =>
        match copy_array (ws,off) len (Some (ds,dstoff)) with
        | None => Some ((s,t), Rerr (Rraise sub_exn_v))
        | Some ws =>
          match store_assign dst (W8array ws) s with
          | Some s' => Some ((s',t), Rval (Conv None []))
          | _ => None
          end
        end
      | _, _ => None
      end
    | Ord, [Litv (CharLit c)] =>
      Some ((s,t), Rval (Litv (IntLit (Z.of_nat (nat_of_ascii c)))))
    | Chr, [Litv (IntLit i)] =>
      Some ((s,t), if (i <? 0)%Z || (i >? 255)%Z
                   then Rerr (Rraise chr_exn_v)
                   else Rval (Litv (CharLit (ascii_of_nat (Z.to_nat i)))))
    | Chopb op, [Litv (CharLit c1); Litv (CharLit c2)] =>
      Some ((s,t), Rval (Boolv (opb_lookup op (Z.of_nat (nat_of_ascii c1))
                                           (Z.of_nat (nat_of_ascii c2)))))
    | Implode, [v] =>
      match val_to_char_list v with
      | Some ls => Some ((s,t), Rval (Litv (StrLit (list_char_to_string ls))))
      | None => None
      end
    | Strsub, [Litv (StrLit str); Litv (IntLit i)] =>
      if (i <? 0)%Z then
        Some ((s,t), Rerr (Rraise sub_exn_v))
      else
        let n := Z.to_nat i in
        match String.get n str with
        | Some n' => Some ((s,t), Rval (Litv (CharLit n')))
        | None    => Some ((s,t), Rerr (Rraise sub_exn_v))
        end
    | StrLen, [Litv (StrLit str)] =>
      Some ((s,t), Rval (Litv (IntLit (Z.of_nat (String.length str)))))
    | Strcat, [v] =>
      match val_to_list v with
      | Some vs =>
        match vals_to_string vs with
        | Some str =>
          Some ((s,t), Rval (Litv(StrLit str)))
        | _ => None
        end
      | _ => None
      end
    | VfromList, [v] =>
      match val_to_list v with
      | Some vs => Some ((s,t), Rval (Vectorv vs))
      | None    => None
      end
    | VSub, [Vectorv vs; Litv (IntLit i)] =>
      if (i <? 0)%Z
      then Some ((s,t), Rerr (Rraise sub_exn_v))
      else
        let n := Z.to_nat i in
        match nth_error vs n with
        | None    => Some ((s,t), Rerr (Rraise sub_exn_v))
        | Some v' => Some ((s,t), Rval v')
        end
    | Vlength, [Vectorv vs] =>
      Some ((s,t), Rval (Litv (IntLit (Z.of_nat (List.length  vs)))))
    | Aalloc, [Litv (IntLit n); v] =>
      if (n <? 0)%Z
      then Some ((s,t), Rerr (Rraise sub_exn_v))
      else
        let (s',lnum) := store_alloc (Varray (List.repeat v (Z.to_nat n))) s
        in Some ((s',t), Rval (Loc lnum))
    | AallocEmpty, [Conv None []] =>
      let (s',lnum) := store_alloc (Varray []) s
      in Some ((s',t), Rval (Loc lnum))
    | Asub, [Loc lnum; Litv (IntLit i)] =>
      match store_lookup lnum s with
      | Some (Varray vs) =>
        if (i <? 0)%Z then
          Some ((s,t), Rerr (Rraise sub_exn_v))
        else
          let n := Z.to_nat i in
          match nth_error vs n with
          | None    => Some ((s,t), Rerr (Rraise sub_exn_v))
          | Some v' => Some ((s,t), Rval v')
          end
      | _ => None
      end
    | Alength, [Loc n] =>
      match store_lookup n s with
      | Some (Varray ws) =>
        Some ((s,t), Rval (Litv (IntLit (Z.of_nat (List.length ws)))))
      | _ => None
      end
    | Aupdate, [Loc lnum; Litv (IntLit i); v] =>
      match store_lookup lnum s with
      | Some (Varray vs') =>
        if (i <? 0)%Z then
          Some ((s,t), Rerr (Rraise sub_exn_v))
        else
          let n := Z.to_nat i in
          if leb (List.length vs') n
          then Some ((s,t), Rerr (Rraise sub_exn_v))
          else
            match store_assign lnum (Varray (update n v vs')) s with
            | None => None
            | Some s' => Some ((s',t), Rval (Conv None []))
            end
      | _ => None
      end
    | ConfigGC, [Litv (IntLit i); Litv (IntLit j)] =>
      Some ((s,t), Rval (Conv None []))
    | FFI n, [Litv(StrLit conf); Loc lnum] =>
      match store_lookup lnum s with
      | Some (W8array ws) =>
        match call_FFI t n (List.map (fun c' => nat_to_word 8 (nat_of_ascii c'))
                                     (string_to_list_char conf)) ws with
        | Ffi_return _ t' ws' =>
          match store_assign lnum (W8array ws') s with
          | Some s' => Some ((s', t'), Rval (Conv None []))
          | None => None
          end
        | Ffi_final _ outcome =>
          Some ((s, t), Rerr (Rabort (Rffi_error outcome)))
        end
      | _ => None
      end
    | _, _ => None
    end
  end.

Definition do_log (op : lop) (v : val) (e : exp) : option exp_or_val :=
  match op  with
  | And => if val_eq_dec (Boolv true) v
          then Some (Exp e)
          else if val_eq_dec (Boolv false) v
               then Some (Val v)
               else None
  | Or =>  if val_eq_dec (Boolv true) v
          then Some (Val v)
          else if val_eq_dec (Boolv false) v
               then Some (Exp e)
               else None
  end.

Definition do_if (v : val) (e1 e2 : exp) : option exp :=
  if val_eq_dec (Boolv true) v
  then Some e1
  else if val_eq_dec (Boolv false) v
       then Some e2
       else None.

(* Semantic helpers *)

Definition build_constrs (s : nat) (condefs : list (conN * (list ast_t)) ) :=
  List.map
    (fun p => match p with (conN,ts) =>
                        (conN,(length ts, TypeStamp conN s)) end)
    condefs.

Fixpoint build_tdefs (n : nat) (tds : list (list tvarN * typeN * list (conN * list ast_t))) : env_ctor :=
  match tds with
  | [] => alist_to_ns []
  | (tvars,tn,condefs)::tds' => nsAppend
                                (build_tdefs (n + 1) tds')
                                (alist_to_ns (List.rev (build_constrs n condefs)))
  end.

Definition extend_dec_env (env env' : sem_env val) : sem_env val :=
  {| sev := nsAppend (sev env) (sev env'); sec := nsAppend (sec env) (sec env')|}.
