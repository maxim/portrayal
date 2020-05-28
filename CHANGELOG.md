This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

* Add option `define` for overriding nested class name.

## 0.4.0 - 2020-05-16

* Portrayal schema is deep-duped to subclasses. [[commit]](https://github.com/scottscheapflights/portrayal/commit/f346483a379ce9fbdece72cde8b0844f2d22b1cd)

## 0.3.1 - 2020-05-11

* Fix the issue introduced in 0.3.0 where `==` and `eql?` were always treating rhs as another portrayal class. [[commit]](https://github.com/scottscheapflights/portrayal/commit/f6ec8f373c6582f7e8d8f872d289222e4a58f8f6)

## 0.3.0 - 2020-05-09 (yanked)

* No longer compare classes in `==`, use `eql?` for that. [[commit]](https://github.com/scottscheapflights/portrayal/commit/9c5a37e4fb91e35d23b22e208344452930452af7)
* Define a protected writer for every keyword - useful when applying changes after `dup`/`clone`. [[commit]](https://github.com/scottscheapflights/portrayal/commit/1c0fa6c6357a09760dae39165e864238d231a08e)
* Add definition of `#hash` to fix hash equality. Now `hash[object]` will match if `object` is of the same class with the same keywords and values. [[commit]](https://github.com/scottscheapflights/portrayal/commit/ba9e390ab4aea4733ba084ac273da448e313ea53)
* Make `#freeze` propagate to all keyword values. [[commit]](https://github.com/scottscheapflights/portrayal/commit/0a734411a6eac08e2355c4277e09a2a70800d032)
* Make `#dup` and `#clone` propagate to all keyword values. [[commit]](https://github.com/scottscheapflights/portrayal/commit/010632d87d81a8d5b5ea5ff27d3d209cc667b0a5)

## 0.2.0 - 2019-07-03

* It's now possible to specify non-lambda default values, like `default: "foo"`. There is now also a distinction between a proc and a lambda default. Procs are `call`-ed, while lambdas or any other types are returned as-is. In the majority of cases defaults are static values, and there is no need for the performance overhead of making all defaults into anonymous functions. [[commit]](https://github.com/scottscheapflights/portrayal/commit/a1cc9d0fd40e413210f61b945d37b81c87280fee)

## 0.1.0

First version.
