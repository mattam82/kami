Require Import Lts.Syntax Lts.Semantics Lts.Equiv Lts.Refinement Lts.Renaming Lts.Wf.
Require Import Lts.Inline Lts.InlineFacts_2 Lts.Tactics.
Require Import Ex.SC Ex.ProcDec.

Set Implicit Arguments.

Section Inlined.
  Variables opIdx addrSize iaddrSize fifoSize lgDataBytes rfIdx: nat.

  Variable dec: DecT opIdx addrSize iaddrSize lgDataBytes rfIdx.
  Variable execState: ExecStateT opIdx addrSize iaddrSize lgDataBytes rfIdx.
  Variable execNextPc: ExecNextPcT opIdx addrSize iaddrSize lgDataBytes rfIdx.

  Variables opLd opSt opHt: ConstT (Bit opIdx).

  Definition pdec := pdecf fifoSize dec execState execNextPc opLd opSt opHt.
  Hint Unfold pdec: ModuleDefs. (* for kinline_compute *)

  Definition pdecInl: Modules * bool.
  Proof.
    remember (inlineF pdec) as inlined.
    kinline_compute_in Heqinlined.
    match goal with
    | [H: inlined = ?m |- _] =>
      exact m
    end.
  Defined.

End Inlined.

