---
title: "metaKanren: Towards a Metacircular Relational Interpreter"
date: 2025-12-12
---

**Authors:** Bharathi Ramana Joshi, William E. Byrd 
**Venue:** ICFP 2021 - miniKanren Workshop Series 
**Paper:** [PDF](http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf)

[Paper, but there is also a thesis](https://www.academia.edu/RegisterToDownload/academicWelcomeFlow/primaryOccupation?redirect_path=%2F71826810%2FmetaKanren_Towards_a_Relational_Metacircular_Interpreter)

::: {.callout .quote}
metaKanren serves as a good starting point towards a full metacircular interpreter for miniKanren and precisely points out the problems in achieving full metacircularity in miniKanren
:::


::: {.callout .question}
What is a metacircular interpreter?
It is an interpreter that is written in the same programming language that it interprets.
:::


#### Shallow metacircular interpreter

One natural way of implementing a metacircular interpreter is by implementing features in terms of themselves -- i.e a shallow embedding ([[Folding Domain-Specific Languages - Deep and Shallow Embeddings]]). This entails implementing logic variables using logic variables, disjunction using disjunction, and so on.

::: {.callout .note}
In the paper, the authors refer to deep embeddings as using "first-order" semantic representations of the language. First-order here just means not using functions in representing the DSL. This is exactly parallel to the terminology used to describe languages, where in first-order languages don't have first class functions. 
:::


#### TinyRelationalLanguage

![](/images/Pasted image 20251128204537.png)

![](/images/Pasted image 20251128204553.png)

::: {.callout .question}
Difference between interpreting logic variables vs interpreted logic variables
Interpreting = these are logic variables **in miniKanren** used in the interpreter
Interpreted = the ones in the interpreted expression (i.e 
logic variables in the TRL language)
:::


The authors make a key distinction in terminology:

::: {.callout .important}
We reserve the term ”metacircular” for an interpreter that interprets every construct it uses, and instead use the term ”self-interpreter” for an interpreter that interprets only a subset of the constructs it uses
:::


Let's unpack this a little bit: What this is saying is that defining a language feature in terms of the host language yields a "self-interpreter". The interpreter for TRL below is a self-interpreter because we don't interpret every single construct in the TRL language, and instead use miniKanren's features as is. 

As I understand it, this probably also means that _shallow embedding a language in itself_ will yield self-interpreters, by definition since shallow-embedding entail defining languages in terms of the host language.

In contrast, deep-embedding a language in itself should yield "metacircular" interpreters (or at least interpreters that are closer to true metacircularity).


#### Interpreter for TRL

```racket
#lang racket

(require minikanren)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Relational Interpreter for TinyRelationalLanguage (TRL)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (eval-programo program out) 
  (fresh (q ge)
         (== `(run 1 (,q) ,ge) program)
         (symbolo q)
         ; the association list here maps interpreted logic variables to
         ; interpreting logic variables -- in other words, we use miniKanren's
         ; logic variables to implement logic variables in TRL
         (eval-gexpro ge `((,q . ,out)))))

(define (eval-gexpro expr env)
  (conde
   [(fresh (e1 e2 t)
           (== `(== ,e1 ,e2) expr)
           (eval-texpro e1 env t)
           (eval-texpro e2 env t))]
   [(fresh (x x1 ge)
           (== `(fresh (,x) ,ge) expr)
           (symbolo x)
           (eval-gexpro ge `((,x . ,x1) . ,env)))]
   [(fresh (e1 e2)
           (== `(disj ,e1 ,e2) expr)
           (conde
            [(eval-gexpro e1 env)]
            [(eval-gexpro e2 env)]))]
   [(fresh (e1 e2)
           (== `(conj ,e1 ,e2) expr)
           (eval-gexpro e1 env)
           (eval-gexpro e2 env))]))

(define (eval-texpro expr env val)
  (conde
   [(== `(quote ,val) expr)]
   [(symbolo expr) (lookupo expr env val)]))

(define (lookupo expr env val)
  (fresh (x v res)
         (== `((,x . ,v) . ,res) env)
         (conde
          [(==  x expr) (== v val)]
          [(=/= x expr) (lookupo expr res val)])))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Examples
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(run* (x) (eval-programo `(run 1 (z) (== 'cat z)) x))
;; Running this example produces ('cat)
;; This is an intuitive result. 

(run* (x) (eval-programo `(run 1 (z) (== ,x z)) 'cat))
;; Running this example produces ('cat z)
;; While 'cat seems obvious, the fact that z is also an output is interesting.
;; Notice that x is an miniKanren logic variable. Therefore, when evaluating the
;; goal expression (== ,x z), e1 is bound to the miniKanren logic variable x,
;; and since this is being run in a run* context, miniKanren will produce all
;; values that satisfy the goals in each of the branches eval-texpro. For the
;; first branch, x gets bound to `(quote ,t), and t will then go on to be bound
;; to 'cat since z is bound to 'cat (from eval-programo). In order to satisfy
;; the second goal eval-texpro, x must bound to a symbol that exists in the
;; environment (in order for lookupo to succeed). The only such symbol is z!
;; Because remember, z gets bound to 'cat in eval-programo.

(run 4 (e1 e2) (eval-programo `(run 1 (z) (disj ,e1 ,e2)) 'cat))
;; Running this example produces
;; '(((== '_.0 '_.0) _.1)
;;    (_.0 (== '_.1 '_.1))
;;    ((== 'cat z) _.0)
;;    (_.0 (== 'cat z)))
;; You can reason about these results with the idea that both e1, e2 are
;; miniKanren logic variables, and so look for values for them to make
;; eval-gexpro succeed!
```
::: {.callout .question}
As an aside, what would HtDP annotations look like for miniKanren/relational programming?
:::

##### Problems with this approach
- Synthesizing disjunctions will always lead to branches with logic variables--this is because the inner-query (i.e the query in TRL) is always restricted to a `run 1` semantics, so we can only express queries of the form "so-and-so should be one of the answers", never "so-and-so" should be the only answer! This is only possible with embedded `run *` semantics.

::: {.callout .question}
Why can't we have embedded `run *` semantics?
Because this requires the interpreter to express conditions on the success/failures of goals, and means to aggregate all results (by determining if query variables are ground or fresh). This goes against the relational nature of the interpreter! This limitation can be overcome if we had a deep embedding because then the success/failure of goals and freshness of logic variables can be expressed as conditions on the semantic representations.
:::


And so, we need a deep embedding of `miniKanren`!

#### metaKanren




----

::: {.callout .note}
William had mentioned in our last meeting that having aggregation could help in achieving full meta-circular interpreter for miniKanren.
:::



