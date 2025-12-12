---
title: "µKanren: A Minimal Functional Core for Relational Programming"
date: 2025-12-09
---

**Authors:** Jason Hemann, Daniel P. Friedman  
**Venue:** Scheme and Functional Programming Workshop 2013  
**Paper:** [PDF](http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf)

[Interactive miniKanren tutorial](https://io.livecode.ch/learn/webyrd/webmk)

- miniKanren is a logic programming language with constraints (see [Constraint Logic Programming](https://en.wikipedia.org/wiki/Constraint_logic_programming))
- Original published microKanren implementation was 265 lines of Scheme code

::: {.callout .important}

The authors of this paper argue that buried within those 265 lines is a "small, beautiful, relational programming language seeking to get out".
:::


- The authors draw parallels between the design philosophy of microKanren and microkernels (like [BarrelFish](https://github.com/kumarpit/burbotOS)!)--just like microkernels, microKanren pushes a lot of the miniKanren interface to user-space, focusing just on the primitives required to make implementing those interfaces possible

#### What do we need in order to have a miniKanren?

Computation in miniKanren proceeds by the application of "goals" to "states". Goals can either succeed, or fail -- if they succeed, they return a stream of all states that satisfy the goal. `States` store the "substitution list" (i.e mapping of logic variables to their instantiated terms), and the next free variable index (more on this later).

This implies the following types:

``` racket
;; State is (PairOf (AssociationListOf Variable μKanrenTerm) Integer)
;; Goal is State -> (StreamOf State)

(define empty-state '(() . 0))
```

Before moving on, it is important to clarify what constitutes a "term" in microKanren:

::: {.callout .definition}
A term in microKanren is either a logic variable, a primitive racket type (strings, numbers, etc), or a pair of microKanren terms (and consequently, lists). Since microKanren is embedded within Racket, you can use more data structures (such as hashes), but these would simply use a `eqv?` check when checking for unification (therefore, hashes containing logic variables will treat the logic variable literally, rather than running a search for an appropriate value for it).
:::


###### Logic Variables

These are represented as vectors containing a single index--logic variable equality is determined by co-incidence of the indices in the vectors

```racket
;; Integer -> Variable
(define (var c) (vector c))

;; Any -> Boolean
;; interp: Returns true iff the given argument represents a variable 
(define (var? v) (vector? v))

;; Variable Variable -> Boolean
;; interp: Returns true iff the two variables are equal, i.e have the same
;; variable index
(define (var=? v1 v2) (equal? (vector-ref v1 0) (vector-ref v2 0)))
```

###### Substitution List

As mentioned above, this is simply a pair of an association list mapping logic variables to microKanren terms, and the next available free variable index.

```racket
;; Variable μKanrenTerm SubstitutionList -> SubstitutionList
;; interp: Extends the sublist with the (x . v) binding
;; NOTE: Does not check for circular references! 
(define (sublist/extend x v s) `((,x . ,v) . ,s))
```

We define a `walk` operator on a substitution list, whose purpose is to find the term a variable is associated to, if any. If the given term has no binding, or is not a variable, it is returned as is.

```racket
;; μKanrenTerm SubstitutionList -> μKanrenTerm
;; interp: Returns the resolved variable reference if `t` is a variable 
;; and it is bound (non-circularly) in the substitutiion list. Otherwise, 
;; if t is not a variable, returns it as is. Returns false in all other cases.
(define (walk t sublist)
  (let [(binding (and (var? t) (assp (λ (k) (var=? t k)) sublist)))]
    (match binding
      [`(,var . ,value) #:when (var? value) (walk value sublist)]
      [`(,var . ,value) value]
      [_ t])))
```

Note that the Racket doesn't natively provide the `assp` method, it can be found in the `r6rs` module. Or you could use this implementation:

```racket
;; ∀ A, B : (A -> Boolean) (AssociationListOf A B) -> (PairOf A B)
;; interp: Ports the scheme assp function to racket
(define (assp pred alist)
  (for/first ([pair alist] #:when (pred (car pair))) pair))
```

###### Goal Constructors

In microKanren, we have 4 primitive goal constructors
- `==` (i.e unification)
- `call/fresh` (introduces new \[or "fresh"\] logic variables)
- `disj` (logical OR)
- conj (logical AND)

Let's start with the `unify` operator.

::: {.callout .question}
What is unification?
It is the process of finding assigments to logic variables such that LHS and RHS "structurally" eqiuvalent (i.e same syntactic form)
Eg: `(list 1 x) (list y 2)` unifies under the substitution list `((x . 2) (y . 1))`
Informally, you can think about it like a "bidirectional" pattern match.
:::


::: {.callout .important}
miniKanren (and microKanren) support _first-order unification_, i.e unification over first order terms (such as symbols, numnbers, pairs, lists, etc). So logic variables cannot represent functions, for example. I don't understand this too well, but the way I see it, _first-order_ here simply means _pure_ syntactic forms (data) -- no terms representing executable semantics.
:::


```racket
;; μKanrenTerm μKanrenTerm SubstitutionList -> SubstitutionList
;; interp: Given two terms, returns the SubstitutionList under which these 
;; terms "unify", false otherwise
(define (unify u v sublist) 
  (let [(u^ (walk u sublist))
        (v^ (walk v sublist))]
    (cond 
      [(and (var? u^)
            (var? v^)
            (var=? u^ v^))
       sublist]
      [(var? u^) (sublist/extend u^ v^ sublist)]
      [(var? v^) (sublist/extend v^ u^ sublist)]
      [(and (pair? u^)
            (pair? v^))
       (let [(sublist^ (unify (car u^) (car v^) sublist))]
         ;; Note the threaded sublist! Why is this important? -- Because
         ;; elements in the tail could be the same as those in the head, and should use the bindings from earlier in the list, if they exist
         (if sublist^ (unify (cdr u^) (cdr v^) sublist^) #f))]
      [else (if (eqv? u^ v^) sublist #f)])))

```

::: {.callout .important}
Notice that if we try to unify two distinct but unbound logic variables (example `== x y`), our implementation will produce a substitution list with `x => y`
:::


Now that we have `unify`, implementing `==` is fairly straightforward.

```racket
;; μKanrenTerm μKanrenTerm -> Goal
;; interp: Goal constructor that only contributes values if the given terms 
;; unify in the given state
(define (== u v)
  (λ (s/c) ; read s/c as state/counter
    (let [(res (unify u v (car s/c)))]
      (if res 
          (stream/unit `(,res . ,(cdr s/c)))
          (stream/zero)))))
```

Note the monadic `stream/unit`, and `stream/zero` methods. I discuss this towards the end of my notes.

###### `call/fresh`

This is the primitive that allows you to introduce new logic variables.

```racket
;; Variable -> Goal -> Goal
;; interp: Binds formal parameter of f to a new logic variable and runs the 
;; body of f (which is a goal) with given substitution list and the now 
;; incremented fresh variable counter
(define (call/fresh f)
  (λ (s/c)
    (let [(index (cdr s/c))]
      ((f (var index)) `(,(car s/c) . ,(add1 index))))))
```

The final two goal constructors, `disj` and `conj`, are defined entirely in terms of the `Stream` monad methods.

```racket
;; Goal Goal -> Goal
;; interp: Given two goals, produces a new goal that returns all states that
;; satisfy either of these goals
(define (disj g1 g2) (λ (s/c) (stream/mplus (g1 s/c) (g2 s/c))))

;; Goal Goal -> Goal
;; interp: Given two goals, produces a new goal that returns only those states
;; that satisfy both of the goals in question
(define (conj g1 g2) (λ (s/c) (stream/bind (g1 s/c) g2)))
```

This warrants a slightly more detailed discussion of the `Stream` monad.

###### Stream Monad

Here is the entire `Stream` monad interface we use in this microKanren implementation. The implementation of this interface is what controls the search strategy.

```racket
;; Stream is one of:
;; - '()
;; - (-> Stream) [Immature Stream]
;; - (cons State Stream) [Mature Stream]

;; State -> (StreamOf State)
(define (stream/unit v) (list v))

;; -> (StreamOf State)
(define (stream/zero) (list))

;; (StreamOf State) (StreamOf State) -> (StreamOf State)
(define (stream/mplus $1 $2)
  (cond [(null? $1) $2]
        [(procedure? $1) (λ () (stream/mplus $2 ($1)))] ; --> SUBTLE
        [else (cons (car $1) (stream/mplus (cdr $1) $2))]))

;; (StreamOf State) Goal -> (StreamOf State)
(define (stream/bind $ g)
  (cond [(null? $) '()]
        [(procedure? $) (λ () (stream/bind ($) g))]
        [else (cons (g (car $)) (stream/bind (cdr $) g))]))
```

- Firstly, note that we need "immature" streams in order to support infinite search spaces. Without it, infinite relations like `fives` below will not terminate.

```racket
(define (fives x) (disj (== x 5) (fives x)))
```

In fact, `fives` as written above will not terminate _even with immature streams_ unless we make a minor adjustment:

```racket
(define (fives x) (disj (== x 5)
						(lambda (s/c) 
							(lambda () ((fives x) s/c)))))
```

^ this transformation is called the `inverse-η-delay`

Another really subtle point -- notice the ordering arguments near the `SUBTLE` annotation. If the ordering instead were: `($1) $2`, it could be possible that elements of the `$2` stream are never surfaced--this would happen in the case that `$1` is an infinite stream! To ensure fairness, miniKanren uses an "interleaving" search strategy, which is achieved simply by re-ordering the arguments to `stream/mplus` each time an immature stream is encountered.

As an example:

```racket
(define (fives x) (disj (== x 5) (λ (s/c) (λ () ((fives x) s/c)))))
(define (sixes x) (disj (== x 6) (λ (s/c) (λ () ((sixes x) s/c)))))
(define (five-and-sixes x) (disj (fives x) (sixes x)))

((call/fresh fives-and-sixes) empty-state) ; alternates between 5, 6
```

#### Reification
TODO

