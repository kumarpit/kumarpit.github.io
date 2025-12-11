---
title: "Notes on Purely Functional Data Structures"
book: "Purely Functional Data Structures by Chris Okasaki"
date: 2025-12-12
---

#### Chapter 1: Introduction
- In functional languages, you get "persistence" for free

::: {.callout .question}
What is persistence?
In imperative languages, data structures rely on destructive assignment, i.e overwriting variables, which means that once yoiu perform some operation on a data structure, you end up changing its internal state and you lose the "old" version of the data structure forever. These data structures are known as ephemeral structures. In functional languages, since data is immutable (for the most part), new structures are "wrappers" around old structures, and so you always have a handle to the old versions. For instance, lists can be destructured to a head and the rest, giving you the old version. I might be misunderstanding this?
:::


- Persistance breaks amortized analyses
	- [Amortized analysis](https://courses.cs.cornell.edu/cs3110/2021sp/textbook/eff/amortized_persistence.html)
- Strict languages are clearly superior to lazy languages in at least one regard: analyzing runtimes, since in lazy languages, it is very, very hard to determine if a piece will ever be run

::: {.callout .quote}

… from the point of view of designing and implementing efficient data structures, functional programming's stricture against destructive updates (i.e., assignments) is a staggering handicap, tantamount to confiscating a master chef's knives. Like knives, destructive updates can be dangerous when misused, but tremendously effective when used properly. Imperative data structures often rely on assignments in crucial ways, and so different solutions must be found for functional programs.
:::


This book is about the fact that, even though immutability and other functional features _may_ seem limiting, it is possible for purely functional data structures to be as efficient (asymptotically) as their mutable counterparts. Furthermore:

::: {.callout .quote}

Until this research, it was widely believed that amortization was incompatible with persistence [DST94, Ram92]. However, we show that memoization, in the form of lazy evaluation, is the key to reconciling the two.
:::

#### Chapter 2: Lazy Evalutation and $-notation

Supporting lazy evaluation in a strict language involves the addition of two primitives:
- Delay
- Force

![[Pasted image 20251210203350.png]]

- Wrapping calls with delay/force is very verbose, so this chapter introduces a more succint, neater $-based syntax
- Prepending an expression with $ will suspend it - $ parses as far to the right as possible -- you can nest suspensions -- `$$e`
- The $-notation is integration with pattern matching as well - avoiding the need for nested case expressions

Example (ML-esque pseudocode):
```
integer, T stream => T stream
fun take(n, s) =
	delay(fn () => case n of 
					0 => Nil
					_ => case (force s) of
						Nil => Nil
						| Cons(x, s') => Cons(x, take(n - 1, s')))
```

Now, using the neater $ integration with pattern matching (matching against a pattern prepended with $ will first force the expression and then match against the stuff after the $):
```
integer, T stream -> T stream
fun take(n, s) = $case (n, s) of  -- note the $ before case, the result type is a stream so this is necessary
					(0, _) => Nil
					(_, $Nil) => Nil
					(_, $Cons(x, s')) => Cons(x, take(n-1, s'))
```

::: {.callout .important}

Why isn't this equivalent to the methods above?
```
integer, T stream -> T stream
fun take(n, s) = $Nil 
| take(_, $Nil) = $Nil
| take(_, $Cons(x, s')) = $Cons(x, take(n - 1, s'))
```
Because in this method, the input stream is forced at the time when `take` is applied -- not when the stream returned by `take` is forced! This is unecessary computation and goes against the lazy semantics one would expect `take` to have.
:::


::: {.callout .note}
The difference a lazy list and a stream is that a lazy list, once forced, performs the entire computation -- it is _monolithic_. Streams, on the other hand, _incrementally_ generate the next result.
:::


An example of this behaviour can be expressed by the append function on lazy list and streams:

For lazy lists:
```
fun s ++ t = $(force s @ force t)
```

^ when this is force, the entire computation is performed.

And for streams:
```
t stream, t stream -> t stream
fun s ++ t = $case s of 
			$Nil => force t
			| $Cons(x, s') => Cons(x, s' ++ t)
```

^ when this is forced, only the first step in the computation of appending the streams is performed.

#### Chapter 3: Amortization and Persistence via Lazy Evaluation



