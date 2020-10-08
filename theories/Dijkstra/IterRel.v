From Coq Require Import Logic.Classical_Prop.
From Paco Require Import paco.
From Coq Require Import Init.Wf.
From Coq Require Import Arith.Wf_nat.
From Coq Require Import Program.Equality.
From Coq Require Import Lia.
Section IterRel.

  Context (A : Type).
  Context (r : A -> A -> Prop).

  Variant not_wf_F (F : A -> Prop) (a : A) : Prop :=
    | not_wf (a' : A) (Hrel : r a a') (Hcorec : F a') .
  Hint Constructors not_wf_F.

  Lemma not_wf_F_mono sim sim' a 
        (IN : not_wf_F sim a)
        (LE : sim <1= sim') : not_wf_F sim' a.
  Proof.
    destruct IN. eauto.
  Qed.
        
  Lemma not_wf_F_mono' : monotone1 not_wf_F.
  Proof.
    red. intros. eapply not_wf_F_mono; eauto.
  Qed.
  Hint Resolve not_wf_F_mono' : paco.

  Definition not_wf_from : A -> Prop :=
    paco1 not_wf_F bot1.

  Inductive wf_from (a : A) : Prop :=
    | base : (forall a', ~ (r a a')) -> wf_from a
    | step : (forall a', r a a' -> wf_from a') -> wf_from a
  .
  Hint Constructors wf_from.
  Lemma neg_wf_from_not_wf_from_l : forall (a : A),
      ~(wf_from a) -> not_wf_from a.
  Proof.
    pcofix CIH. intros. pfold. destruct (classic (exists a', r a a' /\ ~ ( wf_from a') )).
    - destruct H as [a' [Hr Hwf] ]. econstructor; eauto.
    - assert (forall a', ~ r a a' \/ wf_from a').
      {
        intros.
        destruct (classic (r a a')); auto. destruct (classic (wf_from a')); auto.
        exfalso. apply H. exists a'. auto.
      }
      clear H.
      exfalso. apply H0. clear H0. apply step. intros. destruct (H1 a'); auto.
  Qed.

  Lemma neg_wf_from_not_wf_from_r : forall (a : A),
      not_wf_from a -> ~ (wf_from a).
  Proof.
    intros. intro Hcontra. punfold H.  inversion H. pclearbot. clear H. generalize dependent a'. 
    induction Hcontra; intros.
    - apply H in Hrel. auto.
    - punfold Hcorec. inversion Hcorec. pclearbot. specialize (H0 a' Hrel a'0 Hrel0).
      auto.
  Qed.

  Lemma neg_wf_from_not_wf_from : forall (a : A),
      not_wf_from a <-> ~(wf_from a).
  Proof.
    split; try apply neg_wf_from_not_wf_from_r; try apply neg_wf_from_not_wf_from_l.
  Qed.

  Lemma classic_wf : forall (a : A), wf_from a \/ not_wf_from a.
  Proof.
    intros. destruct (classic (wf_from a)); auto.
    apply neg_wf_from_not_wf_from in H. auto.
  Qed.

  Lemma intro_not_wf : forall (P : A -> Prop) (f : A -> A) (a : A),
    P a -> (forall a1 a2, P a1 -> r a1 a2 -> P a2 ) -> (forall a, P a -> r a (f a)) ->
    not_wf_from a.
  Proof.
    intros. generalize dependent a. pcofix CIH. intros. pfold.
    apply not_wf with (a' := f a).
    - auto using H1.
    - right. apply CIH. eapply H0; eauto.
  Qed.
  (**)


  Lemma intro_wf : forall (P : A-> Prop) (m : A -> nat) (a : A),
      P a -> (forall a1 a2, P a1 -> r a1 a2 -> P a2 ) -> 
      (forall a1 a2, P a1 -> r a1 a2 -> m a2 < m a1) -> wf_from a.
  Proof.
    intros. remember (m a) as ma. assert (m a <= ma). lia. clear Heqma. 
    generalize dependent a.  
    induction (ma) as [  | n IHn] eqn : Heq.
    - subst. intros. apply base. intros. intro.  
      assert (~ m a' < m a).
      {  lia. }
      apply H4. clear H4. auto.
    - intros. Abort.


  
End IterRel.

Definition rel_rev {A : Type} (r : A -> A -> Prop) : A -> A -> Prop := fun a0 a1 => r a1 a0.

(*note that my notion of well_founded is sort of reverse of theres*)
Lemma well_found_wf_from : forall (A : Type) (r : A -> A -> Prop), 
    well_founded (rel_rev r) -> forall a, wf_from A r a.
Proof.
  intros A r Hwf a. unfold well_founded in Hwf.
  unfold rel_rev in *. induction (Hwf a). apply step. intros.
  apply H0 in H1. auto.
Qed.

(*Less than is well founded*)

(*my well founded should be closed under subrelation*)

Lemma wf_from_sub_rel : forall (A : Type) (r0 r1 : A -> A -> Prop) (a : A),
    subrelation r0 r1 -> wf_from A r1 a -> wf_from A r0 a.
Proof.
  intros. induction H0.
  - apply base. intros a' Hcontra. apply H in Hcontra. eapply H0; eauto.
  - apply step. intros a' Hr0aa'. apply H in Hr0aa'. auto.
Qed.

Lemma wf_from_gt : forall (n : nat), wf_from nat (fun n0 n1 => n0 > n1) n.
Proof.
  intros.
  enough (forall n', n' <= n -> wf_from nat (fun n0 n1 => n0 > n1) n' ); auto.
  induction n; intros.
  - assert (n' = 0); try lia. subst. apply base. intros. lia.
  - apply step. intros n'' Hn''. assert (n'' <= n); try lia. auto.
Qed.
(*induct on f a*)
Lemma no_inf_dec_seq_aux : forall  (r : nat -> nat -> Prop) (n: nat),
    (forall n1 n2, r n1 n2 -> n1 > n2) ->
     wf_from nat r n.
Proof.
  intros. eapply wf_from_sub_rel; try apply wf_from_gt. 
  repeat intro. auto.
Qed.

(*Possibly uses some kind of transitivity in > that is missing in my more general proofs,
  a more general proof would be nice but I think the nat captures most of what people want*)
Lemma wf_intro_gt : forall (A : Type) (r : A -> A -> Prop) (f : A -> nat) (P : A -> Prop) (a : A),
    (forall a1 a2, P a1 -> r a1 a2 -> P a2) -> 
    (forall a1 a2, P a1 -> r a1 a2 -> f a1 > f a2) -> 
    P a -> wf_from A r a.
Proof.
  intros A r f inv a Hinv Hgt Ha. 
  remember (f a) as n0. 
  generalize dependent a. 
  enough (forall a, f a <= n0 -> inv a -> wf_from A r a).
  {
    intros. apply H. lia. auto.
  }
  induction n0; intros.
  - apply base. assert (f a = 0); try lia. 
    intros a' Hcontra. 
    specialize (Hgt a a' H0 Hcontra). lia. 
  - apply step. intros a' Ha'. 
    apply IHn0; eauto.
    assert (f a > f a'); eauto. lia.
Qed.


(*
Definition injective {A B: Type} (r : A -> B -> Prop) := forall a, exists b, r a b.

Lemma wf_intro_r : forall (A B : Type) (ra : A -> A -> Prop) (rb : B -> B -> Prop)
                   (rab : A -> B -> Prop) (a : A) (b : B), 
    injective rab ->
    (forall a1 a2 b1 b2, ra a1 a2 -> rab a1 b1 -> rab a2 b2 -> rb b1 b2) ->
    rab a b ->
    wf_from B rb b -> wf_from A ra a.
Proof.
  intros. rename H into Hinj. rename H0 into Hresp. rename H1 into Hab.  rename H2 into Hb.
  induction Hb.
  - apply base. intros a' Ha'. rename a0 into b. destruct  (Hinj a') as [b' Hb']. 
    apply H with (a' := b'). eapply Hresp; eauto.
  - rename a0 into b. eapply H0; eauto.
Abort.
    (*maybe if I had a more general notion of subrelation where r0 and r1 can be different types*)
 (*problem seems to be more fundamental than I thought*)
    (*ultimately this theorem is about injecting one type into another and inferring stuff from the image*)
    (*mayb rab must be injective*)

Lemma wf_intro_f : forall (A B : Type) (ra : A -> A -> Prop) (rb : B -> B -> Prop)
                   (f : A -> B) (a : A), (forall a1 a2, ra a1 a2 -> rb (f a1) (f a2) ) ->
                   wf_from B rb (f a) -> wf_from A ra a.
Proof.
  intros. dependent induction H0.
  - apply base. intros a' Hcontra. apply H0 with (a' := f a'). auto.
  -eapply H0; auto.
 Abort.
*)
