---
title: "Gradual Typing for Functional Languages"
---

[Siek, Jeremy G., and Walid Taha. "Gradual Typing for Functional Languages"](http://scheme2006.cs.uchicago.edu/13-siek.pdf)

### What is "gradual" typing?
Gradual typing offers a flexible approach to type systems by combining the features of both static and dynamic typing. It allows developers to decide the level of type strictness they want in their code. You can opt for a fully type-annotated codebase, similar to a statically typed language, or you can omit type annotations in certain sections, allowing those parts to behave like dynamically typed code.

This hybrid approach is especially useful when you're transitioning an existing codebase to a more static type system. Instead of having to annotate the entire project at once, you can gradually add type annotations to different parts of the code over time. Languages and tools that use gradual typing include TypeScript and Sorbet, a static type checker for Ruby.

This paper was the first in presenting a gradual type system that supported structural types (the [BabyJ](https://www.sciencedirect.com/science/article/pii/S1571066104808028?ref=pdf_download&fr=RR-2&rr=96e0091a6da37bf4) paper defined a nominal type system with gradual types). The authors present the gradually typed lambda calculus, and then go on to define the runtime semantics by translating it to an intermediate STLC representation with explicit casts.

Here is the syntax of the gradually-typed lambda calculus:


![Syntax for the gradually-typed lambda calculus](images/gtlc/gtlc.png)


