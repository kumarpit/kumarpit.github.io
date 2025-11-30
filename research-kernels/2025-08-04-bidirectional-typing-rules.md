---
title: "Bidirectional Typing Rules: A Tutorial"
---
---
title: "[Paper] Bidirectional Typing Rules: A Tutorial"
---
[15-312: Foundations of Programming Languages](https://www.cs.cmu.edu/~fp/courses/15312-f04/handouts/15-bidirectional.pdf)


[David Christiansen's tutorial on Bidirectional Typing](https://davidchristiansen.dk/tutorials/bidirectional.pdf)

::: {.callout .note}

Motivation: Type system is not the same thing as an efficient algorithm to check that a term inhabits some type or a means of synthesizing a type for some term.
:::


- It is also not always possible to translate typing rules into an algorithm staightforwardly by treating each rule as a recursive function where premises are called to check the conclusion.
- Only systems that are ***syntax-directed*** may be translated this way -- many actual programming languages are not described in this manner.

::: {.callout .important}
What is a ***syntax-directed*** system?
... is one in which each typing judgement has a unique derivation, determined entirely by the syntactic structure of the term in question. These systems allow typing rules to be considered as pattern-match cases in a recursive function over the term being checked.
:::


- Bidirectional typing rules are one technique for making typing rules syntax-directed -- and therefore enabling the trivial construction of an algorithm for typechecking.

This technique has a few advantages:
- Understandable and produces good error messages
- Relatively few type annotations are required
- Scales well when new features are added to the language

::: {.callout .important}
Bidirectional systems support a style of type annotation where an entire term is annotated once at the top level, rather than sprinkling annotations throughout the code (this seems similar to the style employed by typed racket, Sorbet, etc.)
:::


::: {.callout .question}
How can a typing rule not be syntax-directed?
There are two primary ways in which this may happen:
- it might be ambiguous in the conclusion
- it might contain a premise that is not determined by the conclusion
:::



The author discusses an example of this by using STLC and noting that, in the traditional presentation, the typing rule for abstraction makes the system not be syntax-directed since it requires use to "invent" a type for the argument. This problem is usually solved by providing an annotation for the argument explicitly.

![[Pasted image 20251012212539.png]]


::: {.callout .note}

An alternative solution than bidirectional type checking here is Damas and Milner's Algorithm W
:::



- In the bidirectional typing rule case, we need to introduce a syntax for type annotating an entire term:

$$ t : \mathcal{T} $$



So now, we run the type checker in two modes -- inference mode and type checking -- these mode mutually rely on one another.

#### 1. If you can infer the type of some term, you obviously check against a type

![[Pasted image 20251013104026.png]]

::: {.callout .important}

Notice that you can go from inference to checking mode, but not the other way around (in most cases).
:::


#### 2. Type annotations provide the means of switching from checking mode to inference mode

![[Pasted image 20251013104219.png]]

![[Pasted image 20251013104316.png]]

- Just as the variables bound in function abstractions would require annotations in the syntax-directed unidirectional simply-typed λ-calculus, functions must be checked against some type. This prevents us from having to guess the type τ1 of the argument:

![[Pasted image 20251013104447.png]]


Example derivation for Boolean function composition:

![[Pasted image 20251013105548.png]]

::: {.callout .important}

Remember that the derivation, like the bidirectional typing rules, should be read bottom-to-top and left-to-right. This means that the results of previous “function calls” are available to later “calls”, which is why we have the value to fill out the metavariable with when we check the type of a function argument against the domain of the inferred type of the function.
:::


^ i.e we have $\mathcal{T}_1$ available in the second permise of the function application rule (BT-APP).

![[Pasted image 20251013110047.png]]

#### Drawbacks

While Section 1 presented some of the advantages of a bidirectional type system, there are certainly trade-offs. Perhaps the most serious is that variable substitution no longer works for typing derivations. In particular, the rules provided in Section 1.1 allow a variable in a derivation to be replaced by the derivation for a term of the same type. This is not the case in the bidirectional system of Section 1.2, because variables are checked using inference mode, while many interesting constructs for the language must be checked in checking mode.

In other words:
::: {.callout .important}
In bidirectional systems, `x` can appear in _inference_ positions (like as function argument or head). But `s` might only _check_against `τ`, not _infer_ it. There’s no general rule to turn a checking derivation into an inference one.
:::


An example:
Γ, x : Int ⊢ x ⇒ Int

Γ ⊢ λy. y ⇐ Int → Int

^ both terms here have the same type, but notice that the second term doesn't infer, it just checks against the type. So these terms cannot be used interchangeably.

i.e 
Γ, x : Int → Int ⊢ x 3 ⇒ Int is valid, but
Γ ⊢ (λy. y) 3 ⇒ Int is not!

