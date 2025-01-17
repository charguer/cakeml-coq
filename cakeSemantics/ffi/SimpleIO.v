Require Import Coq.Lists.List.
Require Import Arith.Peano_dec.
Import ListNotations.
Require Import String.
Require Import FFI.
Require Import CakeSem.Word.
Require Import CakeSem.Utils.

Definition simpleIO := ((list word8) * (list word8)) : Set.

Definition isEof
           (st : simpleIO)
           (conf : list word8)
           (input : list word8) : oracle_result simpleIO :=
  match input with
  | [] => Oracle_final simpleIO Ffi_failed
  | x :: xs => Oracle_return simpleIO st ((if list_eq_dec (word_eq_dec 8)
                                           (fst st) []
                                         then (nat_to_word 8 1)
                                         else (nat_to_word 8 0)) :: xs)
  end.

Definition getChar
           (st : simpleIO)
           (conf : list word8)
           (input : list word8) : oracle_result simpleIO :=
  match input with
  | [] => Oracle_final simpleIO Ffi_failed
  | x :: xs => match head (fst st) with
              | Some y => Oracle_return simpleIO (tail (fst st), snd st) (y :: xs)
              | _ => Oracle_final simpleIO Ffi_failed
              end
  end.

Definition putChar
           (st : simpleIO)
           (conf : list word8)
           (input : list word8) : oracle_result simpleIO :=
  match input with
  | [] => Oracle_final simpleIO Ffi_failed
  | x :: _ => Oracle_return simpleIO (fst st, x::(snd st)) input
  end.

Definition exit (st : simpleIO) (conf : list word8) (input : list word8)
  : oracle_result simpleIO := Oracle_final simpleIO Ffi_diverged.

Definition simpleIO_oracle (s : string) (st : simpleIO)
           (conf : list word8) (input : list word8) : oracle_result simpleIO :=
  if string_dec s "isEof"
  then isEof st conf input
  else if string_dec s "getChar"
  then getChar st conf input
  else if string_dec s "putChar"
  then putChar st conf input
  else if string_dec s "exit"
  then exit st conf input
  else Oracle_final simpleIO Ffi_failed.