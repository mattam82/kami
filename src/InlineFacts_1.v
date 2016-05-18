Require Import Bool List String.
Require Import Lib.CommonTactics Lib.Struct Lib.StringBound.
Require Import Lib.ilist Lib.Word Lib.FMap Lib.StringEq.
Require Import Syntax SemanticsExprAction Equiv Inline.

Require Import FunctionalExtensionality.

Lemma inlineDm_SemAction_intact:
  forall {retK} or a nr calls (retV: type retK),
    SemAction or a nr calls retV ->
    forall dmn dmb,
      None = M.find dmn calls ->
      SemAction or (inlineDm a (dmn :: dmb)%struct) nr calls retV.
Proof.
  induction 1; intros.

  - simpl.
    remember (getBody meth (dmn :: dmb)%struct s) as omb;
      destruct omb.
    + exfalso; subst.
      unfold getBody in Heqomb.
      remember (string_eq _ _) as seq; destruct seq; [|discriminate].
      apply string_eq_dec_eq in Heqseq.
      subst; rewrite M.find_add_1 in H0; inv H0.
    + subst.
      unfold getBody in Heqomb.
      remember (string_eq _ _) as seq; destruct seq.
      * apply string_eq_dec_eq in Heqseq.
        subst; rewrite M.find_add_1 in H0; inv H0.
      * apply string_eq_dec_neq in Heqseq.
        rewrite M.find_add_2 in H0 by intuition auto.
        econstructor; eauto.

  - simpl; constructor; auto.
  - simpl; econstructor; eauto.
  - simpl; econstructor; eauto.

  - subst; eapply SemIfElseTrue; eauto.
    + apply IHSemAction1.
      rewrite M.find_union in H1.
      destruct (M.find dmn calls1); auto.
    + apply IHSemAction2.
      rewrite M.find_union in H1.
      destruct (M.find dmn calls1); auto; inv H1.

  - subst; eapply SemIfElseFalse; eauto.
    + apply IHSemAction1.
      rewrite M.find_union in H1.
      destruct (M.find dmn calls1); auto.
    + apply IHSemAction2.
      rewrite M.find_union in H1.
      destruct (M.find dmn calls1); auto; inv H1.

  - simpl; constructor; auto.
  - simpl; constructor; auto.
Qed.

Lemma inlineDm_correct_SemAction:
  forall (meth: DefMethT) or u1 cm1 argV retV1,
    SemAction or (projT2 (attrType meth) type argV) u1 cm1 retV1 ->
    forall {retK2} a
           u2 cm2 (retV2: type retK2),
      M.Disj u1 u2 -> M.Disj cm1 cm2 ->
      Some (existT _ (projT1 (attrType meth))
                   (argV, retV1)) =
      M.find (attrName meth) cm2 ->
      SemAction or a u2 cm2 retV2 ->
      SemAction or (inlineDm a meth) (M.union u1 u2)
                (M.union cm1 (M.remove (attrName meth) cm2))
                retV2.
Proof.
  induction a; intros; simpl in *.

  - inv H4; destruct_existT.
    remember (getBody meth0 meth s) as ob; destruct ob.
    + unfold getBody in Heqob.
      remember (string_eq _ _) as seq; destruct seq; [|inv Heqob].
      apply string_eq_dec_eq in Heqseq; subst.
      destruct (SignatureT_dec _ _); [|inv Heqob].
      generalize dependent HSemAction; inv Heqob; intros.
      rewrite M.find_add_1 in H3.
      inv H3; destruct_existT.
      simpl; constructor.

      eapply appendAction_SemAction; eauto.
      
      rewrite M.remove_add.
      rewrite M.remove_find_None by assumption.

      destruct meth; apply inlineDm_SemAction_intact; auto.

    + unfold getBody in Heqob.
      remember (string_eq _ _) as seq; destruct seq.

      * apply string_eq_dec_eq in Heqseq; subst.
        destruct (SignatureT_dec _ _); [inv Heqob|].

        { constructor 1 with
          (mret := mret)
            (calls := M.union cm1 (M.remove (attrName meth) calls)).
          - apply M.F.P.F.not_find_in_iff.
            unfold not; intros.
            apply M.F.P.F.not_find_in_iff in HDisjCalls.
            apply M.union_In in H4.
            dest_disj.
            destruct H4; auto.
            rewrite M.F.P.F.remove_in_iff in H4; intuition.
          - meq; clear - n H3; inv H3; destruct_existT; intuition auto.
          - apply H0; auto.
            elim n.
            rewrite M.find_add_1 in H3.
            clear -H3; inv H3; destruct_existT; auto.
        }

      * apply string_eq_dec_neq in Heqseq; subst.
        { constructor 1 with
          (mret := mret)
            (calls := M.union cm1 (M.remove (attrName meth) calls)).
          - apply M.F.P.F.not_find_in_iff.
            unfold not; intros.
            apply M.F.P.F.not_find_in_iff in HDisjCalls.
            apply M.union_In in H4.
            dest_disj.
            destruct H4; auto.
            rewrite M.F.P.F.remove_in_iff in H4; intuition.
          - meq; clear - n H3; inv H3; destruct_existT; intuition auto.
          - apply H0; auto.
            rewrite M.find_add_2 in H3; auto.
        } 
        
  - inv H4; destruct_existT.
    constructor; auto.
  - inv H4; destruct_existT.
    econstructor; eauto.
  - inv H3; destruct_existT.
    constructor 4 with (newRegs := M.union u1 newRegs).
    + apply M.F.P.F.not_find_in_iff.
      apply M.F.P.F.not_find_in_iff in HDisjRegs.
      unfold not; intros.
      apply M.union_In in H3.
      dest_disj.
      intuition.
    + meq.
    + apply IHa; auto.

  - inv H4; destruct_existT.
    + rewrite M.find_union in H3.
      remember (M.find (attrName meth) calls1) as omv1; destruct omv1.
      * remember (M.find (attrName meth) calls2) as omv2; destruct omv2.
        { exfalso.
          specialize (HDisjCalls (attrName meth)); destruct HDisjCalls; elim H4.
          { apply M.F.P.F.in_find_iff; rewrite <-Heqomv1; discriminate. }
          { apply M.F.P.F.in_find_iff; rewrite <-Heqomv2; discriminate. }
        }
        { inv H3.
          rewrite M.union_assoc, M.remove_union, M.union_assoc.
          eapply SemIfElseTrue with
          (newRegs1 := M.union u1 newRegs1)
            (calls1 := M.union cm1 (M.Map.remove (attrName meth) calls1)); eauto.
          { dest_disj; solve_disj. }
          { dest_disj.
            apply M.Disj_remove_2.
            solve_disj.
          }
          { rewrite M.remove_find_None by auto.
            destruct meth; apply inlineDm_SemAction_intact; auto.
          }
        }
      * assert (M.union u1 (M.union newRegs1 newRegs2) =
                M.union newRegs1 (M.union u1 newRegs2)).
        { rewrite M.union_assoc.
          rewrite M.union_comm with (m1:= u1); [|eapply M.Disj_union_1; eauto].
          rewrite <-M.union_assoc; auto.
        }
        rewrite H4; clear H4.

        assert (M.union cm1 (M.remove (attrName meth) (M.union calls1 calls2)) =
                M.union (M.remove (attrName meth) calls1)
                        (M.union cm1 (M.remove (attrName meth) calls2))).
        { rewrite M.remove_union, M.union_assoc.
          rewrite M.union_comm with (m1:= cm1);
            [|apply M.Disj_remove_2; eapply M.Disj_union_1; eauto].
          rewrite <-M.union_assoc; auto.
        }
        rewrite H4; clear H4.
        eapply SemIfElseTrue with
        (newRegs1 := newRegs1)
          (newRegs2 := M.union u1 newRegs2)
          (calls1 := M.remove (attrName meth) calls1)
          (calls2 := M.union cm1 (M.remove (attrName meth) calls2))
        ; eauto.
        { dest_disj.
          apply M.Disj_remove_1.
          solve_disj.
        }
        { rewrite M.remove_find_None by auto.
          destruct meth; eapply inlineDm_SemAction_intact; eauto.
        }

    + rewrite M.find_union in H3.
      remember (M.find (attrName meth) calls1) as omv1; destruct omv1.
      * remember (M.find (attrName meth) calls2) as omv2; destruct omv2.
        { exfalso.
          specialize (HDisjCalls (attrName meth)); destruct HDisjCalls; elim H4.
          { apply M.F.P.F.in_find_iff; rewrite <-Heqomv1; discriminate. }
          { apply M.F.P.F.in_find_iff; rewrite <-Heqomv2; discriminate. }
        }
        { inv H3.
          rewrite M.union_assoc, M.remove_union, M.union_assoc.
          eapply SemIfElseFalse with
          (newRegs1 := M.union u1 newRegs1)
            (calls1 := M.union cm1 (M.Map.remove (attrName meth) calls1)); eauto.
          { dest_disj; solve_disj. }
          { dest_disj.
            apply M.Disj_remove_2.
            solve_disj.
          }
          { rewrite M.remove_find_None by auto.
            destruct meth; apply inlineDm_SemAction_intact; auto.
          }
        }
      * assert (M.union u1 (M.union newRegs1 newRegs2) =
                M.union newRegs1 (M.union u1 newRegs2)).
        { rewrite M.union_assoc.
          rewrite M.union_comm with (m1:= u1); [|eapply M.Disj_union_1; eauto].
          rewrite <-M.union_assoc; auto.
        }
        rewrite H4; clear H4.

        assert (M.union cm1 (M.remove (attrName meth) (M.union calls1 calls2)) =
                M.union (M.remove (attrName meth) calls1)
                        (M.union cm1 (M.remove (attrName meth) calls2))).
        { rewrite M.remove_union, M.union_assoc.
          rewrite M.union_comm with (m1:= cm1);
            [|apply M.Disj_remove_2; eapply M.Disj_union_1; eauto].
          rewrite <-M.union_assoc; auto.
        }
        rewrite H4; clear H4.
        eapply SemIfElseFalse with
        (newRegs1 := newRegs1)
          (newRegs2 := M.union u1 newRegs2)
          (calls1 := M.remove (attrName meth) calls1)
          (calls2 := M.union cm1 (M.remove (attrName meth) calls2))
        ; eauto.
        { dest_disj.
          apply M.Disj_remove_1.
          solve_disj.
        }
        { rewrite M.remove_find_None by auto.
          destruct meth; eapply inlineDm_SemAction_intact; eauto.
        }
  - inv H3; destruct_existT.
    constructor; auto.

  - inv H3; destruct_existT.
    rewrite M.find_empty in H2; inv H2.
Qed.

Lemma isLeaf_SemAction_calls:
  forall {retK} G aU aT,
    ActionEquiv (k:= retK) G aT aU ->
    forall lcalls or nr calls retV,
      isLeaf aU lcalls = true ->
      SemAction or aT nr calls retV ->
      forall lc,
        In lc lcalls ->
        M.find lc calls = None.
Proof.
  induction 1; intros.

  - inv H2; destruct_existT.
    destruct (string_dec lc n).
    + subst; simpl in H1.
      apply andb_true_iff in H1; dest.
      remember (string_in _ _) as sin; destruct sin; [inv H1|].
      apply string_in_dec_not_in in Heqsin; elim Heqsin; auto.
    + simpl in H1.
      apply andb_true_iff in H1; dest.
      remember (string_in _ _) as sin; destruct sin; [inv H1|].
      apply string_in_dec_not_in in Heqsin.
      rewrite M.find_add_2 by assumption.
      eapply H0; eauto.

  - inv H2; destruct_existT.
    simpl in H1.
    eapply H0; eauto.
  - inv H2; destruct_existT.
    simpl in H1.
    eapply H0; eauto.
  - inv H1; destruct_existT.
    simpl in H0.
    eapply IHActionEquiv; eauto.
  - inv H3.
    apply andb_true_iff in H7; dest.
    apply andb_true_iff in H3; dest.
    inv H4; destruct_existT; rewrite M.find_union.
    + erewrite IHActionEquiv1; eauto.
    + erewrite IHActionEquiv2; eauto.
  - inv H1; destruct_existT.
    simpl in H0.
    eapply IHActionEquiv; eauto.
  - inv H0; destruct_existT.
    rewrite M.find_empty; auto.
Qed.

Lemma noCallDm_SemAction_calls:
  forall mn (mb: sigT MethodT) G or nr calls argV retV
         (Hmb: ActionEquiv G (projT2 mb type argV) (projT2 mb typeUT tt)),
    noCallDm (mn :: mb)%struct (mn :: mb)%struct = true ->
    SemAction or (projT2 mb type argV) nr calls retV ->
    M.find (elt:=sigT SignT) mn calls = None.
Proof.
  intros; unfold noCallDm in H; simpl in H.
  eapply isLeaf_SemAction_calls; eauto.
  intuition.
Qed.

