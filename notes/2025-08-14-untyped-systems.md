---
title: "Untyped Systems (TAPL 3-7)"
description: "Notes, exercises, and implementations from my reading of 'Types and Programming Languages' chapters 8-11"
---
[Types and Programming Languages by Benjamin C. Pierce](https://www.amazon.com/Types-Programming-Languages-MIT-Press/dp/0262162091)

#### Chapter 3: Untyped Arithmetic Expressions

##### Syntax

There are three ways to define the syntax for our basic untyped arithmetic language:

**Inductively**: The set of terms is the smallest set such that:

1. $\{ \textbf{true}, \textbf{false}, 0 \} \subseteq \mathcal{T}$  
2. If $t_1 \in \mathcal{T}$, then $\{ \text{succ } t_1, \text{pred } t_1, \text{iszero } t_1 \} \subseteq \mathcal{T}$  
3. If $t_1 \in \mathcal{T}$, $t_2 \in \mathcal{T}$, and $t_3 \in \mathcal{T}$, then $\text{if } t_1 \text{ then } t_2 \text{ else } t_3 \in \mathcal{T}$  

The word "smallest" here just means that $\mathcal{T}$ has no elements besides the ones required to satisfy these three clauses. Here, since you only build elements that are, by definition, in the set -- this is equivalent to saying that there are no duplicates (?).

> [!important]
> This is an infinite set!

**By inference rules**: The set of terms $T$ is defined by the following rules:

$$
\text{true} \in T
\quad
\text{false} \in T
\quad
0 \in T
$$

$$
\frac{t_1 \in T}{\text{succ } t_1 \in T}
\qquad
\frac{t_1 \in T}{\text{pred } t_1 \in T}
\qquad
\frac{t_1 \in T}{\text{iszero } t_1 \in T}
$$

$$
\frac{t_1 \in T \quad t_2 \in T \quad t_3 \in T}
{\text{if } t_1 \text{ then } t_2 \text{ else } t_3 \in T}
$$

These are read as: "If premise is true (stuff above the line), then we can derive the conclusion (stuff below the line)".

The rules with no premises are known as "axioms".

> [!important]
> What we are calling inference rules here are actually "rule schemas" -- since their premises and conclusions may include metavariables. Each schema represents an infinite set of concrete rules that can be obtained by replacing the metavariables with all their appropriate values.

**Concretely**: For each natural number $i$, define a set $S_i$ as follows:

$$
S_0 = \varnothing
$$

$$
\begin{aligned}
S_{i+1} =\;& \{ \text{true}, \text{false}, 0 \} \\
&\cup \{ \text{succ } t_1, \text{ pred } t_1, \text{ iszero } t_1 \mid t_1 \in S_i \} \\
&\cup \{ \text{if } t_1 \text{ then } t_2 \text{ else } t_3 \mid t_1, t_2, t_3 \in S_i \}
\end{aligned}
$$

Finally, let

$$
S = \bigcup_i S_i.
$$


> [!exercise] 3.2.4
> How many elements does $S_3$ have?
> A general formula for the number of elements in each set is given by $|S_{i+1}| = 3 + 3 \times S_i + |S_i|^3$. We have that $|S_0| = 0$, so $|S_3| = 59,439$.

> [!exercise] 3.2.5
> Show that the sets $S_i$ are cumulative--that is, that for each $i$, we have $S_i \subseteq S_{i+1}$.
> Proof. This can be shown by a simple inductive proof. 
> _Base Case_: For $i=0$, we have that $S_0 = \emptyset$, so it follows trivially that $S_0 \subseteq S_1$
> Inductive Hypothesis: Assume that for some $j \geq 0$, we have that for all $i < j$ $S_i \subseteq S_{i+1}$.
> Inductive Step: We need to show that $S_i \subseteq S_j$. We do a case-by-case analysis on the types of terms:
> 1. It follows by the definition of $S_j$ that all the constants are in $S_j$.
> 2. For some term of the type $\text{succ }t$, $\text{pred }t$, or $\text{iszero }t$, it follows that $t \in S_{i-1}$, and therefore, by the inductive hypothesis, $t \in S_i$. Then, by the construction of $S_j$, we can see that $\text{succ }t$, $\text{pred }t$, and $\text{iszero }t$ are all in $S_j$.
> 3. Follows similarly to 2.

- The first two definitions for defining the set of possible terms in the language "simply characterize the set as the smallest set satisfying certain closure properties", while the concrete definition shows you how to actually construct the set as a limit of a sequence."
- We can prove that these two definitions are equivalent by showing that $\mathcal{T} = \mathcal{S}$ by showing that $\mathcal{S}$ satisfies the conditions satisfied by $\mathcal{T}$ and by showing that if any set $\mathcal{S}'$ satisfies these conditions, then $\mathcal{S} \subseteq \mathcal{S}'$

> [!important] Induction is a prominent theme in working with programming language semantics

 > How terms are evaluated in a language is known as the "semantics" of the language

There are 3 main approaches to formalizing semantics:
- Operational Semantics
- Denotational Semantics
- Axiomatic Semantics

This book deals exclusively with operational semantics.

##### Evaluation

> [!definition]
> An evaluation relation is a binary relation between terms `t -> t'` (pronounced `t` evaluates to `t'` in one step).

- An inference rule is a set of premises and a conclusion

> [!note] Definition
> An instance of an inference rule is obtained by consistently substituting each metavariable with the same term in the conclusion and all premises.

> [!defintion]
> A rule is _satisfied_ by a relation (i.e `t -> t'`) if, for each instance of the rule, either the conclusion is in the relation, or one of its premises is not.

> [!question]
> Not sure what is meant here by "or one of its premises is not" since the evaluation relations are evaluated against inference rules using just their statements.
> A: OH, it means that in the case that a relation matches a rule, the premises of the rule are also derivable (using values for meta-variables based on the relation).

> [!definition]
> When the pair `(t, t')` is in the evaluation relation that satisfies the inference rules, we say that the evaluation statement (or judgement) `t -> t'` is derivable. Another way of reading this is that an evaluation statement is derivable iff you could conjure a derivation tree with `t -> t'` as its root.

^ This property leads directly to a proof technique called _induction on derivations_.

