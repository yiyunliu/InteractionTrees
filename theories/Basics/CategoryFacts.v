(** * General facts about categories *)

(* begin hide *)
From Coq Require Import
     Setoid Morphisms.

From ITree.Basics Require Import
     CategoryOps CategoryTheory.

Import Carrier.
Import CatNotations.
Local Open Scope cat.
(* end hide *)

(** ** Isomorphisms *)

Section IsoFacts.

Context {obj : Type} {C : Hom obj}.
Context {Eq2C : Eq2 C} {IdC : Id_ C} {CatC : Cat C}.

Context {CatIdL_C : CatIdL C}.

(** [id_] is an isomorphism. *)
Global Instance SemiIso_Id {a} : SemiIso C (id_ a) (id_ a) := {}.
Proof. apply cat_id_l. Qed.

Context {Equivalence_Eq2_C : forall a b, @Equivalence (C a b) eq2}.

Section IsoCat.

Context {CatAssoc_C : CatAssoc C}.
Context {Proper_Cat_C : forall a b c,
            @Proper (C a b -> C b c -> _) (eq2 ==> eq2 ==> eq2) cat}.

(** Isomorphisms are closed under [cat]. *)
Global Instance SemiIso_Cat {a b c}
       (f : C a b) {f' : C b a} {SemiIso_f : SemiIso C f f'}
       (g : C b c) {g' : C c b} {SemiIso_g : SemiIso C g g'}
  : SemiIso C (f >>> g) (g' >>> f') := {}.
Proof.
  rewrite cat_assoc, <- (cat_assoc g), (semi_iso g _), cat_id_l,
  (semi_iso f _).
  reflexivity.
Qed.

End IsoCat.

Section IsoBimap.

Context {bif : binop obj}.
Context {Bimap_bif : Bimap C bif}.
Context {BimapId_bif : BimapId C bif}.
Context {BimapCat_bif : BimapCat C bif}.
Context {Proper_Bimap_bif : forall a b c d,
            @Proper (C a b -> C c d -> _) (eq2 ==> eq2 ==> eq2) bimap}.

(** Isomorphisms are closed under [bimap]. *)
Global Instance SemiIso_Bimap {a b c d} (f : C a b) (g : C c d)
         {f' : C b a} {SemiIso_f : SemiIso C f f'}
         {g' : C d c} {SemiIso_g : SemiIso C g g'} :
  SemiIso C (bimap f g) (bimap f' g') := {}.
Proof.
  rewrite bimap_cat, (semi_iso f _), (semi_iso g _), bimap_id.
  reflexivity.
Qed.

End IsoBimap.

End IsoFacts.

(** ** Categories *)

Section CategoryFacts.

Context {obj : Type} {C : Hom obj}.

Context {Eq2_C : Eq2 C}.
Context {E_Eq2_C : forall a b, @Equivalence (C a b) eq2}.

Context {Id_C : Id_ C} {Cat_C : Cat C}.

Context {i : obj}.
Context {Initial_i : Initial C i}.
Context {InitialObject_i : InitialObject C i}.

(** The initial morphism is unique. *)
Lemma initial_unique :
  forall a (f g : C i a), f ⩯ g.
Proof.
  intros.
  rewrite (initial_object f), (initial_object g).
  reflexivity.
Qed.

End CategoryFacts.

(** ** Bifunctors *)

Section BifunctorFacts.

Context {obj : Type} {C : Hom obj}.

Context {Eq2_C : Eq2 C}.
Context {E_Eq2_C : forall a b, @Equivalence (C a b) eq2}.

Context {Id_C : Id_ C} {Cat_C : Cat C}.

Context {Category_C : Category C}.

Context {bif : binop obj}.
Context {Bimap_bif : Bimap C bif}
        {Bifunctor_bif : Bifunctor C bif}.

Lemma bimap_slide {a b c d} (ac: C a c) (bd: C b d) :
  bimap ac bd ⩯ bimap ac (id_ _) >>> bimap (id_ _) bd.
Proof.
  rewrite bimap_cat, cat_id_l, cat_id_r.
  reflexivity.
Qed.

Lemma bimap_slide' {a b c d} (ac: C a c) (bd: C b d) :
  bimap ac bd ⩯ bimap (id_ _) bd >>> bimap ac (id_ _).
Proof.
  rewrite bimap_cat, cat_id_l, cat_id_r.
  reflexivity.
  all: typeclasses eauto.
Qed.

End BifunctorFacts.

(** ** Coproducts *)

Section CoproductFacts.

Context {obj : Type} {C : Hom obj}.

Context {Eq2_C : Eq2 C}.
Context {E_Eq2_C : forall a b, @Equivalence (C a b) eq2}.

Context {Id_C : Id_ C} {Cat_C : Cat C}.

Context {Category_C : Category C}.

Context {bif : binop obj}.
Context {CoprodCase_C : CoprodCase C bif}
        {CoprodInl_C : CoprodInl C bif}
        {CoprodInr_C : CoprodInr C bif}.
Context {Coproduct_C : Coproduct C bif}.

(** Commute [cat] and [case_]. *)
Lemma cat_case
      {a b c d} (ac : C a c) (bc : C b c) (cd : C c d)
  : case_ ac bc >>> cd ⩯ case_ (ac >>> cd) (bc >>> cd).
Proof.
  apply case_universal.
  - rewrite <- cat_assoc, case_inl.
    reflexivity.
  - rewrite <- cat_assoc, case_inr.
    reflexivity.
Qed.

(** Case analysis with projections is the identity. *)
Corollary case_eta {a b} : id_ (bif a b) ⩯ case_ inl_ inr_.
Proof.
  apply case_universal; rewrite cat_id_r; reflexivity.
Qed.

Lemma case_eta' {a b c} (f : C (bif a b) c) :
  f ⩯ case_ (inl_ >>> f) (inr_ >>> f).
Proof.
  eapply case_universal; reflexivity.
Qed.

(** We can prove the equivalence of morphisms on coproducts
    by case analysis. *)
Lemma coprod_split {a b c} (f g : C (bif a b) c) :
  (inl_ >>> f ⩯ inl_ >>> g) ->
  (inr_ >>> f ⩯ inr_ >>> g) ->
  f ⩯ g.
Proof.
  intros. rewrite (case_eta' g).
  apply case_universal; assumption.
Qed.

Lemma inr_swap {a b} : inr_ >>> swap_ a b ⩯ inl_.
Proof.
  unfold swap, Swap_Coproduct. rewrite case_inr. reflexivity.
Qed.

Lemma inl_swap {a b} : inl_ >>> swap_ a b ⩯ inr_.
Proof.
  unfold swap, Swap_Coproduct. rewrite case_inl. reflexivity.
Qed.

Lemma inr_bimap {a b c d} (f : C a b) (g : C c d)
  : inr_ >>> bimap f g ⩯ g >>> inr_.
Proof.
  unfold bimap, Bimap_Coproduct. rewrite case_inr. reflexivity.
Qed.

Lemma inl_bimap {a b c d} (f : C a b) (g : C c d)
  : inl_ >>> bimap f g ⩯ f >>> inl_.
Proof.
  unfold bimap, Bimap_Coproduct. rewrite case_inl. reflexivity.
Qed.

Lemma bimap_case {a a' b b' c}
      (fa : C a a') (fb : C b b') (ga : C a' c) (gb : C b' c)
  : bimap fa fb >>> case_ ga gb ⩯ case_ (fa >>> ga) (fb >>> gb).
Proof.
  unfold bimap, Bimap_Coproduct.
  rewrite cat_case.
  rewrite 2 cat_assoc, case_inl, case_inr.
  reflexivity.
Qed.

Lemma inl_assoc_r {a b c}
  : inl_ >>> assoc_r_ a b c ⩯ bimap (id_ a) inl_.
Proof.
  unfold assoc_r, AssocR_Coproduct, bimap, Bimap_Coproduct.
  rewrite case_inl, cat_id_l.
  reflexivity.
Qed.

Lemma inl_assoc_l {a b c}
  : inl_ >>> assoc_l_ a b c ⩯ inl_ >>> inl_.
Proof.
  unfold assoc_l, AssocL_Coproduct.
  rewrite case_inl.
  reflexivity.
Qed.

Lemma inr_assoc_l {a b c}
  : inr_ >>> assoc_l_ a b c ⩯ bimap inr_ (id_ c).
Proof.
  unfold assoc_l, AssocL_Coproduct, bimap, Bimap_Coproduct.
  rewrite case_inr, cat_id_l.
  reflexivity.
Qed.

Lemma inr_assoc_r {a b c}
  : inr_ >>> assoc_r_ a b c ⩯ inr_ >>> inr_.
Proof.
  unfold assoc_r, AssocR_Coproduct.
  rewrite case_inr.
  reflexivity.
Qed.

(** The coproduct is a bifunctor. *)

Global Instance Proper_Bimap_Coproduct {a b c d}:
  @Proper (C a b -> C c d -> _)
          (eq2 ==> eq2 ==> eq2) bimap.
Proof.
  intros ac ac' eqac bd bd' eqbd.
  unfold bimap, Bimap_Coproduct.
  rewrite eqac, eqbd; reflexivity.
Qed.

Global Instance BimapId_Coproduct : BimapId C bif.
Proof.
  intros A B.
  symmetry. unfold bimap, Bimap_Coproduct.
  rewrite 2 cat_id_l.
  apply case_eta.
Qed.

Global Instance BimapCat_Coproduct : BimapCat C bif.
Proof.
  red; intros.
  unfold bimap, Bimap_Coproduct.
  apply coprod_split.
  - rewrite <- cat_assoc, !case_inl, !cat_assoc, case_inl.
    reflexivity.
  - rewrite <- cat_assoc, !case_inr, !cat_assoc, case_inr.
    reflexivity.
Qed.

Global Instance Bifunctor_Coproduct : Bifunctor C bif.
Proof.
  constructor; typeclasses eauto.
Qed.

(** The coproduct is commutative *)

Global Instance SwapInvolutive_Coproduct {a b : obj}
  : SemiIso C (swap_ a b) swap.
Proof.
  red; unfold swap, Swap_Coproduct.
  rewrite cat_case, case_inl, case_inr.
  symmetry; apply case_eta.
Qed.

(** The coproduct is associative *)

Global Instance AssocRMono_Coproduct {a b c : obj}
  : SemiIso C (assoc_r_ a b c) assoc_l.
Proof.
  red; unfold assoc_r, assoc_l, AssocR_Coproduct, AssocL_Coproduct.
  rewrite !cat_case.
  rewrite !cat_assoc, !case_inr, !case_inl.
  rewrite <- cat_case, <- case_eta, cat_id_l, <- case_eta.
  reflexivity.
Qed.

Global Instance AssocLMono_Coproduct {a b c : obj}
  : SemiIso C (assoc_l_ a b c) assoc_r.
Proof.
  red; unfold assoc_r, assoc_l, AssocR_Coproduct, AssocL_Coproduct.
  rewrite !cat_case.
  rewrite !cat_assoc, !case_inl, !case_inr.
  rewrite <- cat_case, <- case_eta, cat_id_l, <- case_eta.
  reflexivity.
Qed.

Context (i : obj).
Context {Initial_i : Initial C i}.
Context {InitialObject_i : InitialObject C i}.

(** The coproduct has units. *)

Global Instance UnitLMono_Coproduct {a : obj}
  : SemiIso C (unit_l_ i a) unit_l'.
Proof.
  red; unfold unit_l, unit_l', UnitL_Coproduct, UnitL'_Coproduct.
  rewrite cat_case, cat_id_l, initial_object.
  rewrite <- initial_object.
  symmetry; apply case_eta.
Qed.

(* TODO: derive this by symmetry *)
Global Instance UnitRMono_Coproduct {a : obj}
  : SemiIso C (unit_r_ i a) unit_r'.
Proof.
  red; unfold unit_r, unit_r', UnitR_Coproduct, UnitR'_Coproduct.
  rewrite cat_case, cat_id_l, initial_object.
  rewrite <- initial_object.
  symmetry; apply case_eta.
Qed.

Global Instance UnitLEpi_Coproduct {a : obj}
  : SemiIso C (unit_l'_ i a) unit_l.
Proof.
  red; unfold unit_l, unit_l', UnitL_Coproduct, UnitL'_Coproduct.
  rewrite case_inr. reflexivity.
Qed.

Global Instance UnitREpi_Coproduct {a : obj}
  : SemiIso C (unit_r'_ i a) unit_r.
Proof.
  red; unfold unit_r, unit_r', UnitR_Coproduct, UnitR'_Coproduct.
  rewrite case_inl. reflexivity.
Qed.

Lemma inr_unit_l {a} : inr_ >>> unit_l ⩯ id_ a.
Proof.
  apply (semi_iso _ _).
Qed.

Lemma inl_unit_r {a} : inl_ >>> unit_r ⩯ id_ a.
Proof.
  apply (semi_iso _ _).
Qed.

Global Instance UnitLNatural_Coproduct : UnitLNatural C bif i.
Proof.
  red; intros.
  apply coprod_split.
  - rewrite <- !cat_assoc.
    transitivity (empty : C i b); [ | symmetry ]; auto using initial_object.
  - rewrite <- !cat_assoc, inr_bimap, inr_unit_l, cat_assoc,
      inr_unit_l, cat_id_l, cat_id_r.
    reflexivity.
Qed.

Global Instance UnitL'Natural_Coproduct : UnitL'Natural C bif i.
Proof.
  red; intros.
  unfold unit_l', UnitL'_Coproduct.
  rewrite inr_bimap.
  reflexivity.
Qed.

(** The coproduct satisfies the monoidal coherence laws. *)

Global Instance AssocRUnit_Coproduct : AssocRUnit C bif i.
Proof.
  intros a b.
  unfold assoc_r, AssocR_Coproduct, bimap, Bimap_Coproduct.
  rewrite !cat_id_l.
  eapply case_universal.
  - rewrite <- cat_assoc, case_inl.
    rewrite cat_case, case_inl.
    unfold unit_r, UnitR_Coproduct.
    rewrite cat_case, cat_id_l.
    apply (coproduct_proper_case _ _).
    + reflexivity.
    + eapply initial_unique; auto.
  - rewrite <- cat_assoc, case_inr.
    rewrite cat_assoc, case_inr.
    rewrite <- cat_assoc, inr_unit_l, cat_id_l.
    reflexivity.
Qed.

(* TODO: automate this *)
Global Instance AssocRAssocR_Coproduct : AssocRAssocR C bif.
Proof.
  intros a b c d.
  unfold bimap, Bimap_Coproduct.
  rewrite !cat_id_l.
  rewrite !cat_case.
  unfold assoc_r, AssocR_Coproduct.
  apply coprod_split.
  - rewrite case_inl.
    rewrite <- (cat_assoc inl_).
    rewrite case_inl.
    rewrite !cat_assoc.
    apply coprod_split.
    + repeat (rewrite <- (cat_assoc inl_), !case_inl).
      apply coprod_split.
      * repeat (rewrite <- (cat_assoc inl_), !case_inl).
        reflexivity.
      * repeat (rewrite <- (cat_assoc inr_), !case_inr).
        rewrite cat_assoc.
        rewrite <- (cat_assoc inr_), !case_inr.
        rewrite cat_assoc.
        rewrite case_inr.
        rewrite <- (cat_assoc inl_ _ inr_), case_inl.
        rewrite <- cat_assoc, case_inl.
        reflexivity.
    + repeat (rewrite <- (cat_assoc inr_), !case_inr).
      rewrite <- (cat_assoc inl_), !case_inl.
      rewrite !cat_assoc.
      rewrite <- (cat_assoc inr_ (case_ _ _) _), !case_inr.
      rewrite cat_assoc, case_inr.
      rewrite <- (cat_assoc inl_ (case_ _ _)), case_inl.
      rewrite <- !cat_assoc, case_inr.
      reflexivity.
  - rewrite !case_inr.
    rewrite !cat_assoc.
    repeat (rewrite <- (cat_assoc inr_ (case_ _ _)), !case_inr).
    rewrite !cat_assoc, case_inr.
    reflexivity.
Qed.

Global Instance Monoidal_Coproduct : Monoidal C bif i.
Proof.
  constructor.
  all: try typeclasses eauto.
  all: constructor; typeclasses eauto.
Qed.

(* TODO: automate this. This should follow from the above by symmetry. *)
Global Instance AssocLAssocL_Coproduct : AssocLAssocL C bif.
Proof.
  intros a b c d.
  unfold bimap, Bimap_Coproduct.
  rewrite !cat_id_l.
  rewrite !cat_case.
  unfold assoc_l, AssocL_Coproduct.
  apply coprod_split.
  - rewrite !case_inl.
    rewrite !cat_assoc.
    repeat (rewrite <- (cat_assoc inl_ (case_ _ _)), !case_inl).
    rewrite !cat_assoc, case_inl.
    reflexivity.
  - rewrite case_inr.
    rewrite <- (cat_assoc inr_).
    rewrite case_inr.
    rewrite !cat_assoc.
    apply coprod_split.
    + repeat (rewrite <- (cat_assoc inl_), !case_inl).
      rewrite <- (cat_assoc inr_), !case_inr.
      rewrite !cat_assoc.
      rewrite <- (cat_assoc inl_ (case_ _ _) _), !case_inl.
      rewrite cat_assoc, case_inl.
      rewrite <- (cat_assoc inr_ (case_ _ _)), case_inr.
      rewrite <- !cat_assoc, case_inl.
      reflexivity.
    + repeat (rewrite <- (cat_assoc inr_), !case_inr).
      apply coprod_split.
      * repeat (rewrite <- (cat_assoc inl_), !case_inl).
        rewrite cat_assoc.
        rewrite <- (cat_assoc inl_), !case_inl.
        rewrite cat_assoc.
        rewrite case_inl.
        rewrite <- (cat_assoc inr_ _ inl_), case_inr.
        rewrite <- cat_assoc, case_inr.
        reflexivity.
      * repeat (rewrite <- (cat_assoc inr_), !case_inr).
        reflexivity.
Qed.

(** The coproduct satisfies the symmetric monoidal laws. *)

Global Instance SwapUnitL_Coproduct : SwapUnitL C bif i.
Proof.
  intros a.
  unfold swap, Swap_Coproduct, unit_l, UnitL_Coproduct, unit_r, UnitR_Coproduct.
  apply coprod_split.
  - rewrite <- cat_assoc, !case_inl, case_inr.
    reflexivity.
  - rewrite <- cat_assoc, !case_inr, case_inl.
    reflexivity.
Qed.

(* TODO: automate *)
Global Instance SwapAssocR_Coproduct : SwapAssocR C bif.
Proof.
  intros a b c.
  unfold assoc_r, AssocR_Coproduct, swap, Swap_Coproduct, bimap, Bimap_Coproduct.
  apply coprod_split.
  - rewrite !cat_assoc.
    rewrite <- 2 (cat_assoc inl_), !case_inl.
    rewrite !cat_assoc.
    rewrite <- (cat_assoc inl_), !case_inl.
    apply coprod_split.
    + rewrite <- 2 (cat_assoc inl_), !case_inl.
      rewrite <- cat_assoc. rewrite case_inl.
      rewrite <- cat_assoc, !case_inr.
      rewrite cat_assoc, case_inr.
      rewrite <- cat_assoc, case_inl.
      reflexivity.
    + rewrite <- 2 (cat_assoc inr_), !case_inr.
      rewrite cat_assoc.
      rewrite <- (cat_assoc inr_), case_inr, !case_inl.
      rewrite <- cat_assoc, !case_inl.
      rewrite cat_id_l.
      reflexivity.
  - rewrite !cat_assoc.
    rewrite <- 2 (cat_assoc inr_), !case_inr.
    rewrite cat_id_l.
    rewrite cat_assoc, <- (cat_assoc inr_ (case_ _ _) _), !case_inr, case_inl, case_inr.
    rewrite <- cat_assoc.
    rewrite case_inr, cat_assoc, case_inr, <- cat_assoc, case_inr.
    reflexivity.
Qed.

Global Instance SwapAssocL_Coproduct : SwapAssocL C bif.
Proof.
  intros a b c.
  unfold assoc_l, AssocL_Coproduct, swap, Swap_Coproduct, bimap, Bimap_Coproduct.
  apply coprod_split.
  - rewrite !cat_assoc.
    rewrite <- 2 (cat_assoc inl_), !case_inl.
    rewrite cat_id_l.
    rewrite cat_assoc, <- (cat_assoc inl_ (case_ _ _) _), !case_inl, case_inr, case_inl.
    rewrite <- cat_assoc.
    rewrite case_inl, cat_assoc, case_inl, <- cat_assoc, case_inl.
    reflexivity.
  - rewrite !cat_assoc.
    rewrite <- 2 (cat_assoc inr_), !case_inr.
    rewrite !cat_assoc.
    rewrite <- (cat_assoc inr_), !case_inr.
    apply coprod_split.
    + rewrite <- 2 (cat_assoc inl_), !case_inl.
      rewrite cat_assoc.
      rewrite <- (cat_assoc inl_), case_inl, !case_inr.
      rewrite <- cat_assoc, !case_inr.
      rewrite cat_id_l.
      reflexivity.
    + rewrite <- 2 (cat_assoc inr_), !case_inr.
      rewrite <- cat_assoc. rewrite case_inr.
      rewrite <- cat_assoc, !case_inl.
      rewrite cat_assoc, case_inl.
      rewrite <- cat_assoc, case_inr.
      reflexivity.
Qed.

Global Instance SymMonoidal_Coproduct : SymMonoidal C bif i.
Proof.
  constructor; typeclasses eauto.
Qed.

Lemma swap_bimap {a b c d} (ab : C a b) (cd : C c d) :
  bimap ab cd ⩯ (swap >>> bimap cd ab >>> swap).
Proof.
  unfold bimap, Bimap_Coproduct, swap, Swap_Coproduct.
  apply coprod_split.
  - rewrite case_inl.
    rewrite cat_assoc, <- cat_assoc, case_inl.
    rewrite <- cat_assoc, case_inr.
    rewrite cat_assoc, case_inr.
    reflexivity.
  - rewrite case_inr.
    rewrite cat_assoc, <- cat_assoc, case_inr.
    rewrite <- cat_assoc, case_inl.
    rewrite cat_assoc, case_inl.
    reflexivity.
Qed.

(* Naturality of swap *)
Lemma swap_bimap' {a b c d} (ab : C a b) (cd : C c d) :
  swap >>> bimap ab cd ⩯ bimap cd ab >>> swap.
Proof.
  rewrite swap_bimap, <- !cat_assoc, swap_involutive, cat_id_l.
  reflexivity.
Qed.

End CoproductFacts.

Hint Rewrite @case_inl : cocartesian.
Hint Rewrite @case_inr : cocartesian.

(** Iterative categories are traced. *)
Section TracedIterativeFacts.

Context {obj : Type} (C : Hom obj).

Context {Eq2_C : Eq2 C}.
Context {E_Eq2_C : forall a b, @Equivalence (C a b) eq2}.

Context {Id_C : Id_ C} {Cat_C : Cat C}.
Context {Proper_cat : forall a b c,
          @Proper (C a b -> C b c -> C a c) (eq2 ==> eq2 ==> eq2) cat}.

Context {Category_C : Category C}.

Context (bif : binop obj).
Context {CoprodCase_C : CoprodCase C bif}
        {CoprodInl_C : CoprodInl C bif}
        {CoprodInr_C : CoprodInr C bif}.
Context {Coproduct_C : Coproduct C bif}.
Context {Proper_case_ : forall a b c,
            @Proper (C a c -> C b c -> C _ c) (eq2 ==> eq2 ==> eq2) case_}.

Context {CatLoop_bif : CatLoop C bif}.
Context {Conway_C : Conway C bif}.
Context {Proper_cat_loop : forall a b,
            @Proper (C a (bif a b) -> C a b) (eq2 ==> eq2) cat_loop}.

Lemma trace_natural_left {a a' b c} (f : C (bif c a) (bif c b)) (g : C a' a)
  : g >>> cat_trace f
  ⩯ cat_trace (bimap (id_ _) g >>> f).
Proof.
  unfold cat_trace.
  transitivity (inr_ >>> cat_loop (bimap (id_ c) g >>> inl_
                                     >>> case_ (f >>> bimap inl_ (id_ b)) inr_)).
  - rewrite loop_dinatural.
    rewrite cat_assoc, case_inl.
    rewrite <- (cat_assoc inr_).
    unfold bimap, Bimap_Coproduct. (* TODO: by naturality of inr_ *)
    rewrite case_inr, cat_assoc.
    repeat (apply Proper_cat; try reflexivity).
    apply Proper_cat_loop.
    rewrite cat_assoc.
    apply Proper_cat; try reflexivity.
    rewrite !cat_id_l.
    rewrite cat_case, !case_inr, cat_assoc, case_inl, <- cat_assoc, case_inl.
    reflexivity.
  - rewrite !cat_assoc, case_inl. reflexivity.
Qed.

Lemma trace_natural_right {a b b' c} (f : C (bif c a) (bif c b)) (g : C b b')
  : cat_trace f >>> g
  ⩯ cat_trace (f >>> bimap (id_ _) g).
Proof.
  unfold cat_trace.
  rewrite cat_assoc.
  apply Proper_cat; try reflexivity.
  rewrite loop_natural.
  apply Proper_cat_loop; try reflexivity.
  rewrite !cat_assoc, !bimap_cat, !cat_id_l, !cat_id_r.
  reflexivity.
Qed.

Lemma trace_dinatural {a b c c'} (f : C (bif c a) (bif c' b)) (g : C c' c)
  : cat_trace (f >>> bimap g (id_ _))
  ⩯ cat_trace (bimap g (id_ _) >>> f).
Proof.
  unfold cat_trace.
  transitivity (inr_ >>> cat_loop (bimap g (id_ a) >>> inl_
                                     >>> case_ (f >>> bimap inl_ (id_ b)) inr_)).
  - rewrite loop_dinatural.
    rewrite <- 2 cat_assoc.
    unfold bimap at 3, Bimap_Coproduct at 3. (* TODO: naturality of [inr_] *)
    rewrite case_inr, cat_id_l, (cat_assoc _ inl_), case_inl.
    apply Proper_cat; try reflexivity.
    rewrite cat_assoc, bimap_cat, cat_id_l.
    unfold bimap, Bimap_Coproduct.
    rewrite !cat_assoc, !cat_case, !cat_id_l, cat_assoc, !case_inl, case_inr.
    rewrite cat_assoc.
    reflexivity.
  - rewrite 2 cat_assoc, case_inl.
    reflexivity.
Qed.

Context (i : obj).
Context {Initial_i : Initial C i}.
Context {InitialObject_i : InitialObject C i}.

Lemma trace_vanishing_1 {a b} (f : C (bif i a) (bif i b))
  : cat_trace f
  ⩯ unit_l' >>> f >>> unit_l.
Proof.
  unfold cat_trace.
  rewrite loop_unfold.
  rewrite !cat_assoc.
  match goal with
  | [ |- _ >>> (_ >>> ?g) ⩯ _ ] =>
    assert (Hg : g ⩯ unit_l)
  end.
  { unfold unit_l, UnitL_Coproduct.
    apply case_universal.
    - apply initial_object.
    - rewrite bimap_case, case_inr, cat_id_l.
      reflexivity.
  }
  rewrite Hg.
  reflexivity.
Qed.

Lemma trace_vanishing_2 {a b c d} (f : C (bif d (bif c a)) (bif d (bif c b)))
  : cat_trace (cat_trace f)
  ⩯ cat_trace (assoc_r >>> f >>> assoc_l).
Proof.
  unfold cat_trace.
  transitivity (inr_ >>> inr_ >>> cat_loop (cat_loop (
                 f >>> bimap inl_ (bimap (inl_ >>> inr_) (id_ _))
               ))).
  - rewrite cat_assoc, loop_natural, cat_assoc, bimap_cat, cat_id_l, cat_id_r.
    transitivity (inr_ >>> cat_loop (inr_ >>> inl_ >>> case_ (cat_loop (
                   f >>> bimap inl_ (bimap inl_ (id_ _))
                 )) inr_)).
    + rewrite cat_assoc, case_inl.
      reflexivity.
    + rewrite loop_dinatural.
      rewrite cat_assoc, case_inl.
      rewrite loop_natural.
      rewrite cat_assoc, bimap_cat, cat_id_r.
      rewrite bimap_case. rewrite <- 2 cat_assoc.
      reflexivity.

  - rewrite loop_codiagonal.
    rewrite (cat_assoc _ (bimap _ _)), bimap_case, cat_id_r.
    transitivity (inr_ >>> cat_loop (
                   (assoc_r >>> inl_) >>>
                   case_ (f >>> assoc_l >>> bimap inl_ (id_ _)) inr_)).
    + rewrite loop_dinatural.
      rewrite <- 2 cat_assoc, inr_assoc_r.
      rewrite (cat_assoc _ inl_), case_inl.
      rewrite !(cat_assoc f).
      match goal with
      | [ |- _ >>> cat_loop (_ >>> ?u) ⩯ _ >>> cat_loop (_ >>> ?v) ] =>
        assert (u ⩯ v)
      end.
      { rewrite cat_assoc, bimap_case.
        rewrite <- cat_assoc, inl_assoc_r.
        apply coprod_split.
        - rewrite case_inl.
          rewrite <- cat_assoc, inl_assoc_l.
          rewrite cat_assoc, case_inl.
          rewrite <- cat_assoc, inl_bimap, cat_id_l.
          reflexivity.
        - rewrite case_inr.
          rewrite <- cat_assoc, inr_assoc_l.
          rewrite bimap_case.
          rewrite <- cat_assoc, inr_bimap.
          unfold bimap, Bimap_Coproduct.
          rewrite !cat_id_l.
          reflexivity.
      }
      rewrite H; clear H.
      reflexivity.
    + rewrite cat_assoc, case_inl.
      rewrite !(cat_assoc assoc_r).
      reflexivity.
Qed.

Lemma trace_superposing {a b c d e}
      (ab : C (bif e a) (bif e b)) (cd : C c d) :
    bimap (cat_trace ab) cd
  ⩯ cat_trace (assoc_l >>> bimap ab cd >>> assoc_r).
Proof.
  unfold cat_trace.
  apply coprod_split.
  - rewrite inl_bimap.
    transitivity (
        inr_ >>> cat_loop (
          (inl_ >>> assoc_r >>> inl_)
            >>> case_ (assoc_l >>> bimap ab cd >>> assoc_r >>> bimap inl_ (id_ _))
                      inr_)).

    + rewrite cat_assoc, loop_natural.
      apply Proper_cat; try reflexivity.
      apply Proper_cat_loop.
      rewrite !cat_assoc.
      rewrite case_inl.
      rewrite <- (cat_assoc inl_), inl_assoc_r.
      rewrite <- (cat_assoc _ assoc_l).
      assert (He : forall a b c, bimap (id_ _) inl_ >>> assoc_l_ a b c ⩯ inl_).
      { intros.
        apply coprod_split.
        - rewrite <- cat_assoc, inl_bimap, cat_assoc, inl_assoc_l, cat_id_l.
          reflexivity.
        - rewrite <- cat_assoc, inr_bimap, cat_assoc, inr_assoc_l, inl_bimap.
          reflexivity.
      }
      rewrite He; clear He.
      rewrite <- (cat_assoc inl_), inl_bimap.
      rewrite cat_assoc, <- (cat_assoc inl_), inl_assoc_r.
      rewrite !bimap_cat, !cat_id_l, !cat_id_r.
      reflexivity.

    + rewrite loop_dinatural.
      rewrite inl_assoc_r.
      rewrite cat_assoc, <- cat_assoc, inr_bimap, case_inl, !cat_assoc.
      assert (Hr : forall a b c d,
                 bimap inl_ (id_ d) >>> case_ (bimap (id_ a) inl_ >>> inl_) inr_
               ⩯ bimap (inl_ : C a (bif a (bif b c))) (id_ d)).
      { intros. apply coprod_split.
        - rewrite <- cat_assoc, !inl_bimap, cat_assoc, case_inl.
          rewrite <- cat_assoc, inl_bimap, cat_id_l.
          reflexivity.
        - rewrite <- cat_assoc, !inr_bimap, cat_assoc, case_inr.
          reflexivity.
      }
      rewrite Hr; clear Hr.
      reflexivity.

  - rewrite inr_bimap.
    rewrite loop_unfold.
    rewrite !cat_assoc.
    rewrite <- (cat_assoc _ assoc_l), inr_assoc_l.
    rewrite <- cat_assoc, inr_bimap, cat_id_l.
    rewrite <- cat_assoc, inr_bimap.
    rewrite cat_assoc.
    rewrite <- (cat_assoc _ assoc_r), inr_assoc_r.
    rewrite cat_assoc, <- (cat_assoc _ (bimap _ _)), inr_bimap, cat_id_l.
    rewrite case_inr, cat_id_r.
    reflexivity.
Qed.

Lemma trace_yanking {a} : cat_trace swap ⩯ id_ a.
Proof.
  unfold cat_trace.
  rewrite 2 loop_unfold.
  rewrite !cat_assoc.
  rewrite <- cat_assoc, inr_swap.
  rewrite <- cat_assoc, inl_bimap.
  rewrite cat_assoc, case_inl.
  rewrite <- cat_assoc, inl_swap.
  rewrite <- cat_assoc, inr_bimap.
  rewrite cat_id_l, case_inr.
  reflexivity.
Qed.

End TracedIterativeFacts.
