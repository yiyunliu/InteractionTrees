(** * Finite Interaction Tree *)

(* begin hide *)
From ITree Require Import
     ITree
     Eq.Eqit
     Leaf.
From ITree Require Import Nondeterminism Exception. (* For counterexamples *)

From Paco Require Import paco.
From Coq Require Import Morphisms Basics Program.Equality.
Import ITree.
Import ITreeNotations.
Import LeafNotations.
(* end hide *)

(** ** Finite computations as Interaction Trees

  We provide two predicates capturing finiteness of an [itree]:
  - [BoxFinite t]     expresses that [t] is finite along all branches
  - [DiamondFinite t] expresses that [t] admits a finite branch

  In each case, we prove:
  - Smart constructors and inversion lemmas
  - Closure under [eutt R] (in the case of [Leaf], we get another value related by R) and Proper instances for [eutt eq]
  - Forward and backward proof rules for [bind]s
  We additionally provide:
  - Particular cases of non-interactive computations and [spin]
  - Counterexamples to properties that could be expected at first glance
*)

(** Definitions *)

(** BoxFinite t
  The tree admits exclusively finite branches *)
Inductive BoxFinite {E} {A: Type} : itree E A -> Prop :=
 | BoxFiniteRet: forall a t,
    observe t = RetF a ->
   BoxFinite t
 | BoxFiniteTau: forall t u,
   observe t = TauF u ->
   BoxFinite u ->
   BoxFinite t
 | BoxFiniteVis: forall {X} (e: E X) t k,
   observe t = VisF e k ->
   (forall x, BoxFinite (k x)) ->
   BoxFinite t
.
#[global] Hint Constructors BoxFinite : itree.

(** DiamondFinite t
  The tree admits at least one finite branch *)
Inductive DiamondFinite {E} {A: Type} : itree E A -> Prop :=
 | DiamondFiniteRet: forall a t,
    observe t = RetF a ->
   DiamondFinite t
 | DiamondFiniteTau: forall t u,
   observe t = TauF u ->
   DiamondFinite u ->
   DiamondFinite t
 | DiamondFiniteVis: forall {X} (e: E X) t k x,
   observe t = VisF e k ->
   DiamondFinite (k x) ->
   DiamondFinite t
.
#[global] Hint Constructors DiamondFinite : itree.

(** Smart constructors *)

(* BoxFinite *)
Lemma BoxFinite_Ret : forall E R a,
  @BoxFinite E R (Ret a).
Proof.
  intros; econstructor 1; reflexivity.
Qed.
#[global] Hint Resolve BoxFinite_Ret : itree.

Lemma BoxFinite_Tau : forall E R t,
  BoxFinite t ->
  @BoxFinite E R (Tau t).
Proof.
  intros; econstructor 2; [reflexivity | eauto].
Qed.
#[global] Hint Resolve BoxFinite_Tau : itree.

Lemma BoxFinite_Vis : forall E X R (e : E X) k,
  (forall x, BoxFinite (k x)) ->
  @BoxFinite E R (Vis e k).
Proof.
  intros; econstructor 3; [reflexivity | eauto].
Qed.
#[global] Hint Resolve BoxFinite_Vis : itree.

(* DiamondFinite *)
Lemma DiamondFinite_Ret : forall E R a,
  @DiamondFinite E R (Ret a).
Proof.
  intros; econstructor 1; reflexivity.
Qed.
#[global] Hint Resolve DiamondFinite_Ret : itree.

Lemma DiamondFinite_Tau : forall E R t,
  DiamondFinite t ->
  @DiamondFinite E R (Tau t).
Proof.
  intros; econstructor 2; [reflexivity | eauto].
Qed.
#[global] Hint Resolve DiamondFinite_Tau : itree.

Lemma DiamondFinite_Vis : forall E X R (e : E X) k x,
  DiamondFinite (k x) ->
  @DiamondFinite E R (Vis e k).
Proof.
  intros; econstructor 3; [reflexivity | eauto].
Qed.
#[global] Hint Resolve DiamondFinite_Vis : itree.

(** Inversion lemmas *)

(* BoxFinite *)
Lemma BoxFinite_Tau_inv : forall E R t,
  @BoxFinite E R (Tau t) ->
  BoxFinite t.
Proof.
  intros * FIN; inv FIN; cbn in *; congruence.
Qed.

Lemma BoxFinite_Vis_inv : forall E X R (e : E X) k,
  @BoxFinite E R (Vis e k) ->
  forall x, BoxFinite (k x).
Proof.
  intros * FIN x; inv FIN; cbn in *; try congruence.
  revert H0.
  refine (match H in _ = u return match u with VisF e0 k0 => _ | _ => False end with eq_refl => _ end).
  auto.
Qed.

(* DiamondFinite *)
Lemma DiamondFinite_Tau_inv : forall E R t,
  @DiamondFinite E R (Tau t) ->
  DiamondFinite t.
Proof.
  intros * FIN; inv FIN; cbn in *; congruence.
Qed.

Lemma DiamondFinite_Vis_inv : forall E X R (e : E X) k,
  @DiamondFinite E R (Vis e k) ->
  exists x, DiamondFinite (k x).
Proof.
  intros * FIN; inv FIN; cbn in *; try congruence.
  revert x H0.
  refine (match H in _ = u return match u with VisF e0 k0 => _ | _ => False end with eq_refl => _ end).
  eauto.
Qed.

(** Closure under [eutt]

  General asymetric lemmas for [eutt R], and [Proper]
  instances for [eutt eq]. *)

(* BoxFinite *)
Lemma BoxFinite_eutt_l {E A B R}:
  forall (t : itree E A) (u : itree E B),
  eutt R t u ->
  BoxFinite t ->
  BoxFinite u.
Proof.
  intros * EQ FIN;
  revert u EQ.
  induction FIN; intros u2 EQ.
  - punfold EQ.
    red in EQ; rewrite H in EQ; clear H.
    remember (RetF a); genobs u2 ou.
    hinduction EQ before R; intros; try discriminate; eauto with itree.
  - punfold EQ; red in EQ; rewrite H in EQ; clear H.
    remember (TauF u); genobs u2 ou2.
    hinduction EQ before R; intros; try discriminate; pclearbot; inv Heqi; eauto with itree.
  - punfold EQ; red in EQ; rewrite H in EQ; clear H.
    remember (VisF e k); genobs u2 ou2.
    hinduction EQ before R; intros; try discriminate; pclearbot.
    + revert H0 H1.
      refine (match Heqi in _ = u return match u with VisF e0 k0 => _ | _ => False end with eq_refl => _ end).
      eauto with itree.
    + inv Heqi; eauto with itree.
Qed.

Lemma BoxFinite_eutt_r {E A B R}:
  forall (t : itree E A) (u : itree E B),
  eutt R t u ->
  BoxFinite u ->
  BoxFinite t.
Proof.
  intros * EQ. apply eqit_flip in EQ. revert EQ. apply BoxFinite_eutt_l.
Qed.

#[global] Instance BoxFinite_eutt {E A R}:
  Proper (eutt R ==> iff) (@BoxFinite E A).
Proof.
  repeat intro; split.
  - eapply BoxFinite_eutt_l; eauto.
  - eapply BoxFinite_eutt_r; eauto.
Qed.

(* DiamondFinite *)
Lemma DiamondFinite_eutt_l {E A B R}:
  forall (t : itree E A) (u : itree E B),
  eutt R t u ->
  DiamondFinite t ->
  DiamondFinite u.
Proof.
  intros * EQ FIN;
  revert u EQ.
  induction FIN; intros u2 EQ.
  - punfold EQ.
    red in EQ; rewrite H in EQ; clear H.
    remember (RetF a); genobs u2 ou.
    hinduction EQ before R; intros; try discriminate; eauto with itree.
  - punfold EQ; red in EQ; rewrite H in EQ; clear H.
    remember (TauF u); genobs u2 ou2.
    hinduction EQ before R; intros; try discriminate; pclearbot; inv Heqi; eauto with itree.
  - punfold EQ; red in EQ; rewrite H in EQ; clear H.
    remember (VisF e k); genobs u2 ou2.
    hinduction EQ before R; intros; try discriminate; pclearbot.
    + revert x FIN IHFIN.
      refine (match Heqi in _ = u return match u with VisF e0 k0 => _ | _ => False end with eq_refl => _ end).
      eauto with itree.
    + inv Heqi; eauto with itree.
Qed.

Lemma DiamondFinite_eutt_r {E A B R}:
  forall (t : itree E A) (u : itree E B),
  eutt R t u ->
  DiamondFinite u ->
  DiamondFinite t.
Proof.
  intros * EQ. apply eqit_flip in EQ. revert EQ. apply DiamondFinite_eutt_l.
Qed.

#[global] Instance DiamondFinite_eutt {E A R}:
  Proper (eutt R ==> iff) (@DiamondFinite E A).
Proof.
  split.
  eapply DiamondFinite_eutt_l; eauto.
  eapply DiamondFinite_eutt_r; eauto.
Qed.

(** Compatibility with [bind], forward and backward *)

(* BoxFinite *)

(* Only the reachable branches, as captured by the
    leaves in the image of the prefix, need to be
   finite in the continuation *)
Lemma BoxFinite_bind : forall {E R S}
  (t : itree E R) (k : R -> itree E S),
  BoxFinite t ->
  (forall x, x ∈ t -> BoxFinite (k x)) ->
  BoxFinite (t >>= k).
Proof.
  intros * FIN; induction FIN; intros FINs;
    rewrite unfold_bind, H; eauto with itree.
Qed.

Lemma BoxFinite_bind_weak : forall {E R S}
  (t : itree E R) (k : R -> itree E S),
  BoxFinite t ->
  (forall x, BoxFinite (k x)) ->
  BoxFinite (t >>= k).
Proof.
  intros; apply BoxFinite_bind; auto.
Qed.

(* We only get finiteness of the reachable branches *)
Lemma BoxFinite_bind_inv : forall {E R S}
  (t : itree E R) (k : R -> itree E S),
  BoxFinite (t >>= k) ->
  (BoxFinite t /\ forall x, x ∈ t -> BoxFinite (k x)).
Proof.
  intros E R S.
  cut (forall (u : itree E S), BoxFinite u ->
       forall (t : itree E R) k, u ≈ t >>= k ->
        (BoxFinite t /\ forall x, x ∈ t -> BoxFinite (k x))).
  intros LEM * FIN; eapply LEM; eauto; reflexivity.
  induction 1; intros * EQ.
  - rewrite (itree_eta t), H in EQ; clear H t.
    symmetry in EQ; apply eqit_inv_bind_ret in EQ as (? & EQt & EQk).
    rewrite EQt; split; auto with itree.
    intros z IN.
    rewrite EQt in IN; apply Leaf_Ret_inv in IN; subst.
    rewrite EQk; auto with itree.
  - rewrite (itree_eta t), H in EQ; clear H t.
    rewrite tau_eutt in EQ.
    eauto.
  - rewrite (itree_eta t), H in EQ; clear H t.
    symmetry in EQ; apply eutt_inv_bind_vis in EQ.
    destruct EQ as [(kca & EQ & EQk) | (?a & EQ & EQk)].
    + rewrite EQ.
      split.
      apply BoxFinite_Vis.
      intros ?; eapply H1; symmetry; eauto.
      intros x IN.
      rewrite EQ in IN.
      apply Leaf_Vis_inv in IN as (y & IN).
      edestruct H1 as (_ & H).
      symmetry in EQk; exact (EQk y).
      apply H, IN.
    + rewrite EQ; split; auto with itree.
      intros y IN.
      rewrite EQ in IN; apply Leaf_Ret_inv in IN; subst.
      rewrite EQk. eauto with itree.
Qed.

Lemma BoxFinite_bind_inv_left : forall {E R S}
  (t : itree E R) (k : R -> itree E S),
  BoxFinite (t >>= k) ->
  BoxFinite t.
Proof.
  intros; eapply BoxFinite_bind_inv; eauto.
Qed.

(* DiamondFinite *)

(* For a [bind] to have a finite branch, we need to
   exhibit a finite branch in [t] that _continues_
   into a finite branch in [k]. We capture this
   continuity using [Leaf].
*)
Lemma DiamondFinite_bind : forall {E R S}
  (t : itree E R) (k : R -> itree E S) x,
  x ∈ t ->
  DiamondFinite (k x) ->
  DiamondFinite (t >>= k).
Proof.
  intros * IN FIN; induction IN.
  - rewrite (itree_eta t), H, bind_ret_l; auto.
  - rewrite unfold_bind, H, tau_eutt; eauto.
  - rewrite unfold_bind, H.
    eapply DiamondFinite_Vis; eauto.
Qed.

(* We get the additional guarantee that the
   finite branch in the continuation comes
   from a point in the image of the prefix.  *)
Lemma DiamondFinite_bind_inv : forall {E R S}
  (t : itree E R) (k : R -> itree E S),
  DiamondFinite (t >>= k) ->
  (DiamondFinite t /\
   exists x, x ∈ t /\ DiamondFinite (k x)).
Proof.
  intros * FIN;
  remember (ITree.bind t k) as u.
  revert t k Hequ.
  induction FIN; intros t' k' ->; rename t' into t.
  - unfold observe in H; cbn in H.
    desobs t EQ; cbn in *; try congruence.
    split; eauto with itree.
  - unfold observe in H; cbn in H.
    desobs t EQ; cbn in *; try congruence.
    split; eauto with itree.
    inversion H; clear H; symmetry in H1.
    edestruct IHFIN as (? & ? & ? & ?).
    apply H1.
    split; eauto with itree.
  - unfold observe in H; cbn in H.
    desobs t EQ; cbn in *; try congruence.
    split; eauto with itree.
    revert x FIN IHFIN.
    refine (match H in _ = u return match u with VisF e0 k0 => _ | _ => False end with eq_refl => _ end).
    intros.
    edestruct IHFIN as (? & ? & ? & ?); [ reflexivity | ].
    split; eauto with itree.
Qed.

Lemma DiamondFinite_bind_inv_weak : forall {E R S}
  (t : itree E R) (k : R -> itree E S),
  DiamondFinite (t >>= k) ->
  (DiamondFinite t /\
   exists x, DiamondFinite (k x)).
Proof.
  intros * FIN; apply DiamondFinite_bind_inv in FIN as (?&?&?&?).
  split; eauto.
Qed.

Lemma DiamondFinite_bind_inv_left : forall {E R S}
  (t : itree E R) (k : R -> itree E S),
  DiamondFinite (t >>= k) ->
  DiamondFinite t.
Proof.
  intros; eapply DiamondFinite_bind_inv; eauto.
Qed.

(** * [DiamondFinite] is non-empty [Leaf] *)
Lemma Leaf_Diamond : forall E R (t : itree E R) x,
  x ∈ t ->
  DiamondFinite t.
Proof.
  intros * FIN; induction FIN; rewrite itree_eta, H; eauto with itree.
Qed.

Lemma Diamond_Leaf : forall E R (t : itree E R),
  DiamondFinite t ->
  exists x, x ∈ t.
Proof.
  intros * FIN; induction FIN.
  1: exists a; rewrite itree_eta, H; eauto with itree.
  all: destruct IHFIN; eauto with itree.
Qed.

(** Degenerate case of non-interactive computations
  In the absence of interaction ([E = void1]), [BoxFinite] and [DiamondFinite] collapse:
  we indeed both know that the computation is deterministic,
  and that it cannot fail, excluding hence any subtletly.
  The image is either empty, or a singleton.
*)

Lemma Box_Diamond_non_interactive : forall X (t: itree void1 X),
  BoxFinite t <-> DiamondFinite t.
Proof.
  split; induction 1; cbn in *; first [now destruct e | eauto with itree].
Qed.

Lemma Box_Leaf_non_interactive : forall X (t: itree void1 X),
  BoxFinite t <-> (exists x, x ∈ t).
Proof.
  intros *.
  rewrite Box_Diamond_non_interactive.
  split; [ eauto using Diamond_Leaf | intros []; eauto using Leaf_Diamond ].
Qed.

Lemma Leaf_non_interactive_singleton : forall X (t: itree void1 X) a b,
  a ∈ t -> b ∈ t -> a = b.
Proof.
  intros * IN; revert b; induction IN; intros * IN'.
  - rewrite itree_eta, H in IN'; apply Leaf_Ret_inv in IN'; auto.
  - rewrite itree_eta, H, tau_eutt in IN'; eauto.
  - inv e.
Qed.

(** [spin] is not finite, in any sense of the term *)
Lemma spin_not_BoxFinite: forall E X,
  ~ BoxFinite (@spin E X).
Proof.
  intros * FIN; remember spin as t; revert Heqt; induction FIN; intros ->;
  unfold observe in H; cbn in H; inv H; auto.
Qed.

Lemma spin_not_DiamondFinite: forall E X,
  ~ DiamondFinite (@spin E X).
Proof.
  intros * FIN; remember spin as t; revert Heqt; induction FIN; intros ->;
  unfold observe in H; cbn in H; inv H; auto.
Qed.

Lemma spin_empty_Leaf: forall E X x,
  ~ x ∈ (@spin E X).
Proof.
  intros * IN; apply Leaf_Diamond, spin_not_DiamondFinite in IN; auto.
Qed.

Module Counterexamples.

(** * Counterexamples *)

(** Counterexamples to statements that could be expected to be true at firt glance. *)

(** [BoxFinite] does _not_ entail [DiamondFinite].

  Indeed, Diamond guarantees that a finite branch exists,
  where Box enforces that no infinite branch exists.
  If the computation has no branch, Box can be satisfied
  while Diamond is not.
  The [fail] computation is the simplest counterexample *)

  Notation fail := (@throw unit (exceptE _) _ unit tt).

  Fact fail_BoxFinite: BoxFinite fail.
  Proof.
    unfold fail.
    apply BoxFinite_Vis; intros [].
  Qed.

  Fact fail_not_DiamondFinite: ~ DiamondFinite fail.
  Proof.
    unfold fail; intros FIN.
    apply DiamondFinite_Vis_inv in FIN as ([] & ? & ?).
  Qed.

(** The [bind] proof rule for [DiamondFinite] _must_ quantify
    on the [Leaf]
    It could be tempting to hope for a simpler lemma than
    [DiamondFinite], simply ensure diamond on the prefix and
    at a point in the continuation:
    DiamondFinite t ->
    DiamondFinite (k x) ->
    DiamondFinite (t >>= k)
    It is however primordial to ensure that the finite path exhibited by k
    is reachable for t, as illustrated in the following *)

  Definition t : itree nondetE bool :=
    or (Ret true) spin.

  Definition k : bool -> itree nondetE unit :=
    fun b => if b then spin else Ret tt.

  Lemma spin_not_DiamondFinite: forall E X,
    ~ DiamondFinite (@spin E X).
  Proof.
    intros * FIN; remember spin as t; revert Heqt; induction FIN; intros ->;
    unfold observe in H; cbn in H; inv H; auto.
  Qed.

  Fact DFt : DiamondFinite t.
  Proof.
    apply DiamondFinite_Vis with true; auto with itree.
  Qed.

  Fact DFk : DiamondFinite (k false).
  Proof.
    cbn; auto with itree.
  Qed.

  Fact NotDFtk: ~ DiamondFinite (t >>= k).
  Proof.
  intros abs.
  apply DiamondFinite_bind_inv in abs as (FINt & b & IN & FINk).
  destruct b; cbn in *.
  - eapply spin_not_DiamondFinite; eauto.
  - unfold t in IN.
    clear FINk FINt.
    inv IN; cbn in *; try congruence.
    dependent induction H.
    destruct x; cbn in *.
    apply Leaf_Ret_inv in H0; congruence.
    apply Leaf_Diamond in H0.
    eapply spin_not_DiamondFinite; eauto.
  Qed.

End Counterexamples.
