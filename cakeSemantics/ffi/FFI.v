Require Import Coq.Lists.List.
Import ListNotations.
Require Import String.
Require Import Arith.Peano_dec.
Require Import Bool.Sumbool.
Require Import CakeSem.Word.
Require Import CakeSem.Utils.

Inductive ffi_outcome : Set := Ffi_failed | Ffi_diverged.

Inductive oracle_result (ffi' : Type) : Type :=
| Oracle_return : ffi' -> list word8 -> oracle_result ffi'
| Oracle_final : ffi_outcome -> oracle_result ffi'.

Definition oracle_function (ffi' : Type) := ffi' -> list word8 -> list word8 -> oracle_result ffi'.

Definition oracle (ffi' : Type) := string -> oracle_function ffi'.

Inductive io_event : Set :=
| Io_event : string -> list word8 -> list (word8 * word8) -> io_event.

Inductive final_event : Set :=
| Final_event : string -> list word8 -> list word8 -> ffi_outcome -> final_event.

Definition ffi_state (ffi' : Type) := (((oracle ffi') * ffi') * (list io_event))%type.

Definition initial_ffi_state {ffi' : Type} (oc : oracle ffi') (ffi : ffi') : ffi_state ffi' :=
  (oc, ffi, []).

Inductive ffi_result (ffi' : Type) : Type :=
| Ffi_return : ffi_state ffi' -> list word8 -> ffi_result ffi'
| Ffi_final : final_event -> ffi_result ffi'.

Arguments ffi_result {ffi'}.

Definition call_FFI {ffi' : Type} (st : ffi_state ffi')
           (str : string)
           (conf : list word8)
           (bytes : list word8) : ffi_result :=
  if sumbool_not _ _ (string_dec str "")
  then match st with (orac, x, iol) =>
                     match orac str x conf bytes with
                     | Oracle_return _ ffi bytes' =>
                       if Nat.eqb (List.length bytes') (List.length bytes)
                       then (Ffi_return ffi' (orac, ffi,
                                        iol ++ [Io_event str conf (combine bytes bytes')])
                                       bytes'
                            )
                       else (Ffi_final ffi' (Final_event str conf bytes Ffi_failed))

                     | Oracle_final _ outcome => Ffi_final ffi' (Final_event str conf bytes outcome)
                     end
       end
  else Ffi_return ffi' st bytes.

Inductive outcome : Set :=
| Success : outcome
| Resource_limit_hit : outcome
| Ffi_outcome : final_event  -> outcome.

(* In diverge, the list needs to be lazy because the ioEvents can be infinite *)
Inductive behavior (ffi' : Type) :=
| Diverge : list io_event -> behavior ffi'
| Terminate : outcome -> list io_event -> behavior ffi'
| Fail.

(* fromJust is a problem *)
Definition traceOracle
           (s : string)
           (io_trace : list io_event)
           (conf : list word8)
           (input : list word8) : oracle_result (list io_event) :=
  match head io_trace with
  | Some (Io_event s' conf' bytes2) => if sumbool_and _ _ _ _
                                           (string_dec s s')
                                           (list_eq_dec
                                              (word_eq_dec 8)
                                              (map fst bytes2)
                                              input)
                                      then Oracle_return (list io_event)
                                                         (tail io_trace)
                                                         (map snd bytes2)
                                      else Oracle_final (list io_event) Ffi_failed
  | _ => Oracle_final (list io_event) Ffi_failed
  end.