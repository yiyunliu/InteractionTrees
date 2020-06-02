(** * Monad laws and associated typeclasses *)

(* begin hide *)
From Coq Require Import
     Morphisms.

From ITree Require Import
     Basics.Basics
     Basics.CategoryOps
     Basics.CategoryMonad
     Basics.CategoryTheory
     Basics.Typ
     Basics.HeterogeneousRelations
     Basics.Function.
(* end hide *)

Set Primitive Projections.

Import Carrier.
Import CatNotations.
Local Open Scope cat_scope.
Local Open Scope typ_scope.
Section EqmR.

(* SAZ: really HeterogenousRelations should be proper.  We could remove all those assumptions here. *)
  
  (* We consider heterogeneous relations on computations parameterized by a relation on the return types *)
  (* Rq: if we make [EqMR] a singleton class, the type checker tends to craft dumb instances for itself behind our back.
    I wrapped it up in a record, it seems to prevent this behavior.
  *)
  Class EqmR (m : typ -> typ) : Type :=
    { eqmR : forall (A B : typ) (R : relationH A B), relationH (m A) (m B) ;
      eqmR_equal : forall (A : typ), eq_rel (eqmR A A A) (m A)
    }.

  Arguments eqmR {m _ A B}.

  (*
    The more traditional notion of monadic equivalence is recovered at the equality relation
    [forall A,  m A -> m A -> Prop]
   *)
  Definition eqm {m : typ -> typ} `{@EqmR m} {A: typ} := eqmR A.

End EqmR.

(* YZ: I don't think [A] should be maximally inserted, but putting it back as is for now for retro-compatibility *)
Arguments eqm {m _ A}.
Arguments eqmR {m _ A B}.
Infix "≈" := eqm (at level 70) : monad_scope.

Section EqmRRel.
  Context (m : typ -> typ).
  Context {EqMR : EqmR m}.

  Import RelNotations.
  Local Open Scope relationH_scope.

(*
  Global Instance Proper_transpose_relationH {A B : typ} (R: relationH A B) `{Proper _ (equalE A ==> equalE B ==> iff)%signature R} : Proper (equalE B ==> equalE A ==> iff) (†R).
  Proof.
    repeat red.
    unfold transpose; intros; cbn in *.
    apply H; assumption.
  Qed.

  Global Instance Proper_compose_relationH {A B C: typ}
         (R1: relationH A B)
         (R2 : relationH B C)
         `{Proper _ (equalE A ==> equalE B ==> iff)%signature R1}
         `{Proper _ (equalE B ==> equalE C ==> iff)%signature R2} 
    : Proper (equalE A ==> equalE C ==> iff) (R2 ∘ R1).
  Proof.
    repeat red. unfold HeterogeneousRelations.compose.
    intros; cbn in *.
    split; intros (b & Hxb & Hbx); exists b; split; intros.
    - specialize (H _ _ H1). 
*)  

  (* Requirements of well-formedness of [eqmR] *)
  Class EqmR_OK : Type :=
    {
    (* [eqmR] should transport elementary structures of the relation [R] *)
    (* Question: should it transport anti-symmetry? *)

    eqmR_transport_symm :>  forall {A : typ} (R : relationH A A), Symmetric ↓R -> Symmetric ↓(eqmR R);

    eqmR_transport_trans :> forall {A : typ} (R : relationH A A), Transitive ↓R -> Transitive ↓(eqmR R);

      (* [eqmR] is associative by composing the underlying relationHs *)
    eqmR_rel_trans : forall {A B C : typ}
                       (R1 : relationH A B)
                       (R2 : relationH B C)
                       (ma : m A) (mb : m B) (mc : m C),
        eqmR R1 @ (ma, mb) ->
        eqmR R2 @ (mb, mc) ->
        eqmR (R2 ∘ R1) @ (ma, mc);
  
    eqmR_lift_transpose : forall {A B : typ} (R : relationH A B)
      , eq_rel (eqmR †R) (†(eqmR R));

      (* [eqmR] respects extensional equality of the underlying relationH
         and [eqm] on both arguments over the monad *)
      (* SAZ: We need to restrict this to only Proper relations R, otherwise even
         the identity monad doesn't work.  
         - option 1 : change relationH to be A -=-> B -=-> Prop_type
           keep the old fully-general version

         - option 2 : restrict eqmR_Proper as shown:
      *)
    eqmR_Proper :> forall {A B : typ},
        Proper (eq_rel ==> eq_rel) eqmR;

      (* [eqmR] is monotone as a morphism on relationHs *)
    eqmR_Proper_mono :> forall {A B},
        Proper (@subrelationH _ _ ==> @subrelationH _ _) (@eqmR m _ A B);
    }.

End EqmRRel.

(* In particular, well-formedness of [eqmR] recovers that [eqm] is an equivalence relationH *)
Section EqmRMonad.
  Context (m : typ -> typ).
  Context {EqMRm : EqmR m}.
  Context {Mm : Monad typ_proper m}.

  (* Generalization of monadic laws.
     These are of two quite distinct natures:
     * Heterogeneous generalizations of the usual three monad laws
     * Reasoning principles relating [eqmR R] to [R]
     *)
  Class EqmRMonad :=
    {
      (* SAZ: we can prove only one direction of this law. 
          - for PropT we can take the proposition (fun _ => False)
            which accepts no computations.  Then it is true that (ret a1) and (ret a2)
            are equi-accepted by that proposition, but there doesn't have to be any relation
            between

          - for StateT we can take the void state, which also cannot be inverted.
          
          - However, for some monads we do get the other direction:
            (itree E) and StateT S when S is non-void, for example.  So we
            break the other direction out into a different typeclass that
            can be instantiated differently.
       *)
      eqmR_ret : forall {A1 A2 : typ} (RA : relationH A1 A2) (a1:A1) (a2:A2),
        RA @ (a1, a2) -> eqmR RA @ (ret @ a1, ret @ a2);

      eqmR_bind_ProperH : forall {A1 A2 B1 B2 : typ}
                            (RA : relationH A1 A2)
                            (RB : relationH B1 B2)
                            ma1 ma2
                            (kb1 : A1 -=-> m B1) (kb2 : A2 -=-> m B2),
          eqmR RA @ (ma1, ma2) ->
          (forall a1 a2, RA @ (a1 , a2) -> eqmR RB @ (kb1 @ a1, kb2 @ a2)) ->
          eqmR RB @ (bind kb1 @ ma1, bind kb2 @ ma2);

    (* Question: The following helps _proving_ [eqmR _ (bind _ _)].
       Should we require something to invert such an hypothesis?
    eqmR_Proper_bind :> forall {A1 A2 B1 B2} (RA : A1 -> A2 -> Prop) (RB : B1 -> B2 -> Prop),
        (Proper (eqmR RA ==> (RA ==> (eqmR RB)) ==> eqmR RB) bind);
     *)

      eqmR_bind_ret_l : forall {A B : typ}
                          (f : A -=-> m B)
                          (a : A),

          equalE (m B) (bind f @ (ret @ a)) (f @ a);

      eqmR_bind_ret_r : forall {A B : typ}
                          (ma : m A),
          equalE (m A) (bind ret @ ma) ma;

       (* forall (a b c : obj) (f : C a (M b)) (g : C b (M c)), bind f >>> bind g ⩯ bind (f >>> bind g) *)
      eqmR_bind_bind : forall {A B C : typ}
                       (ma : m A)
                       (f : A -=-> m B)
                       (g : B -=-> m C),
          equalE (m C) ((bind f >>> bind g) @ ma) (bind (f >>> bind g) @ ma)
    }.

  Class EqmRMonadInverses :=
    {
    eqmR_ret_inv : forall {A1 A2 : typ} (RA : relationH A1 A2) (a1:A1) (a2:A2),
        eqmR RA @ (ret @ a1, ret @ a2) -> RA @ (a1, a2)
    }.
  
End EqmRMonad.

Arguments eqmR_bind_ret_l {_ _ _ _}.

Section Laws.

  Context (m : typ -> typ).
  Context {Mm : Monad typ_proper m}.
  Context {EqMR : EqmR m} {EqmRm: EqmRMonad m} {EqmROKm : EqmR_OK m}.
  
  Local Open Scope monad_scope.

  Global Instance monad_eqmR : MonadLaws Mm.
  Proof.
    split; intros.
    - intros x y H.
      pose proof eqmR_bind_ret_l as Hbr.
      specialize (Hbr a b f).
      specialize (Hbr x).
      rewrite <- H.
      apply Hbr.
    - intros x y H. cbn.
      rewrite eqmR_bind_ret_r. apply H. apply EqmRm. eauto. 
    - repeat intro.
      pose proof eqmR_bind_bind.
      rewrite H.
      specialize (H0 m _ _ _ _ _ _ y f g). 
      assumption.
    - repeat intro. rewrite H0. 
      pose proof (eqmR_bind_ProperH).
      specialize (H1 _ _ _ _ a a b b a b x0 y0 x y).
      assert (eqmR a @ (x0, y0)).
      { apply eqmR_equal. assumption. }
      specialize (H1 H2).
      rewrite <- H0 at 1.
      apply eqmR_equal.
      apply H1. intros. apply eqmR_equal. rewrite H3. apply Proper_typ_proper_app.
      apply H. reflexivity.
  Qed.

End Laws.

Lemma rewrite_app_l {A B C:typ} (R: (A × B) -=-> prop_typ) (x1 x2 : A) (y : B)
      (EQ : x1 == x2)
      (H : R @ (x1, y)) : R @ (x2, y).
Proof.
 destruct R.
 cbn in *. 
 pose proof (p (x1, y) (x2, y)). cbn in *. apply H0. split; auto. reflexivity.
 apply H. 
Qed.

Lemma rewrite_app_r {A B C:typ} (R: (A × B) -=-> prop_typ) (x : A) (y1 y2 : B)
      (EQ : y1 == y2)
      (H : R @ (x, y1)) : R @ (x, y2).
Proof.
 destruct R.
 cbn in *. 
 pose proof (p (x, y1) (x, y2)). cbn in *. apply H0. split; auto. reflexivity.
 apply H. 
Qed.
  
Section Domain.

  Context (m : typ -> typ).
  Context {Mm : Monad typ_proper m}.
  Context {EqMR : EqmR m} {EqmRm: EqmRMonad m} {EqmROKm : EqmR_OK m}.
  Context {EqMRI: EqmRMonadInverses m}.

  Program Definition domain {A:typ} (m : m A) : relationH A A :=
    fun p =>
      forall (R : relationH A A)
        (RR : ReflexiveH R)
        (HS : SymmetricH R)
        (TS : TransitiveH R)
        (EQ: eqmR R @ (m, m)), R @ p.
  Next Obligation.
    do 2 red.
    intros (x1 & y1) (x2 & y) (H1 & H2). cbn in *.
    split; intros.
    - specialize (H R).
      eapply rewrite_app_l. apply H1.
      eapply rewrite_app_r. apply H2. apply H; assumption.
    - specialize (H R).
      eapply rewrite_app_l. symmetry. apply H1.
      eapply rewrite_app_r. symmetry. apply H2. apply H; assumption.
  Qed.


  Lemma transpose_eq {A} (R : relationH A A) (x:A) :
    R @ (x, x) <-> (transpose R) @ (x, x).
  Proof.
    split; intros.
    destruct R; cbn in *.
    assumption.
    destruct R; cbn in *.
    assumption.
  Qed.

  Lemma domain_reflexive {A} (ma : m A) : ReflexiveH (domain ma).
  Proof.
    red.
    intros a.
    repeat intro.
    apply RR.
  Qed.
  
  Lemma domain_symmetric {A} (ma : m A) : SymmetricH (domain ma).
  Proof.
    red.
    intros p.
    destruct p. cbn.
    intros.
    pose proof (HS (t, t0)). apply H0. apply H; assumption.
  Qed.

  Lemma domain_transitive {A} (ma : m A) : TransitiveH (domain ma).
  Proof.
    red.
    intros.
    destruct p; destruct q; cbn in *.
    intros.
    pose proof (TS (t, t0) (t1, t2)). apply H2. apply H; assumption.
    apply H0; assumption. apply H1.
  Qed.
  
  Lemma domain_least {A} (ma : m A) (R : relationH A A)
        (RR : ReflexiveH R)
        (HS : SymmetricH R)
        (TS : TransitiveH R)
        (G: eqmR R @ (ma, ma))
    : subrelationH (domain ma) R.
  Proof.
    intros x y D.
    unfold domain in D.
    cbn in *.
    apply D; assumption.
  Qed.

  Global Instance Proper_domain {A} (ma : m A) :
    Proper (equalE A ==> equalE A ==> iff) ↓(domain ma).
  Proof.
    repeat red.
    intros; split; intros.
    - rewrite <- H. rewrite <- H0. assumption.
    - rewrite H. rewrite H0. assumption.
  Qed.

  (* SAZ: TODO - move these to HeterogeneousRelations *)
  Lemma relationH_reflexive : forall (A:typ), ReflexiveH A.
  Proof.
    intros A.
    destruct A; cbn. 
    repeat red. intros. cbn. reflexivity.
  Qed.

  (* SAZ: TODO - move these to HeterogeneousRelations *)
  Lemma relationH_symmetric : forall (A:typ), SymmetricH A.
  Proof.
    intros A.
    destruct A; cbn. 
    repeat red. intros. cbn in *. symmetry; assumption.
  Qed.

    (* SAZ: TODO - move these to HeterogeneousRelations *)
  Lemma relationH_transitive : forall (A:typ), TransitiveH A.
  Proof.
    intros A.
    destruct A; cbn. 
    repeat red. intros. cbn in *.
    destruct p, q. cbn in *.
    eapply transitivity. apply H. eapply transitivity. apply H1. assumption.
  Qed.

  
  Lemma domain_subset {A:typ} (ma : m A) :
    subrelationH (eqmR (domain ma)) (m A).
  Proof.
    unfold subrelationH.
    intros.
    apply eqmR_equal.
    specialize (@domain_least A ma).
    intros P.
    specialize (P (relationH_of_typ A)).
    eapply eqmR_Proper_mono; eauto.
    apply P.
    - apply relationH_reflexive.
    - apply relationH_symmetric.
    - apply relationH_transitive.
    - apply eqmR_equal. apply (@relationH_reflexive (m A)).
  Qed.


  (* Maybe this is what we axiomatize by typeclasses in the interface? *)
  Lemma domain_eqmR {A : typ} (ma : m A) :
      eqmR (domain ma) @ (ma, ma).
  Proof.
  Abort.

  
  (* A sanity check about the domains: *)
  Program Definition singletonR {A:typ} (x:A) : relationH A A :=
    (fun p => (fst p) == (snd p) /\ (fst p) == x).
  Next Obligation.
    do 2 red.
    intros.
    destruct x0, y; cbn in *.
    destruct H.
    split; intros (HA & HB); split.
    - rewrite <- H. rewrite <- H0. assumption.
    - rewrite <- H. assumption.
    - rewrite H. rewrite H0. assumption.
    - rewrite H. assumption.
  Qed.


  (* SAZ : TODO - port these *)
  (*
  Global Instance singletonR_symetric {A:typ} (x:A) : Symmetric (singletonR x).
  Proof.
    repeat red. intros. unfold singletonR in H.
    destruct H. split; symmetry. tauto. rewrite <- H. symmetry. assumption.
  Qed.

  Global Instance singletonR_transitive {A:typ} (x:A) : Transitive (singletonR x).
  Proof.
      repeat red. intros. unfold singletonR in *.
      destruct H, H0; split; etransitivity; eauto. rewrite <- H2. assumption. PER_reflexivity.
  Qed.

  Global Instance singletonR_PER {A:typ} (x:A) : PER (singletonR x).
  Proof.
    split; typeclasses eauto.
  Qed.

  Global Instance Proper_singletonR {A:typ} (x:A) : Proper (equalE A ==> equalE A ==> iff) (singletonR x).
  Proof.
    repeat red; intros; unfold singletonR in *.
    split; intros (HA & HB); split.
    - rewrite <- H. rewrite HA. assumption.
    - rewrite <- H. assumption.
    - rewrite H. rewrite H0. assumption.
    - rewrite H. assumption.
  Qed.

    
  
             
  Lemma ret_domain {A:typ} (x:A) (IN : x ∈ A) : eq_rel (domain (ret @ x)) (singletonR x).
  Proof.
    split.
    - repeat red. intros. 
      unfold domain in H.
      specialize (H (singletonR x) _).
      specialize (H (Proper_singletonR x)).
      assert (eqmR (singletonR x) (ret @ x) (ret @ x)).
      { apply eqmR_ret. typeclasses eauto.  repeat red. split; assumption. }
      apply H in H0. red in H0. assumption.
    - repeat red. intros.
      unfold singletonR in H. destruct H.
      specialize (HP _ _ H0).
      assert (y == x). { symmetry in H.  etransitivity; eauto. }
      specialize (HP _ _ H1). apply HP.
      eapply eqmR_ret_inv; eauto.
  Qed.

    
    
    *)
End Domain.


