This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

* No longer compare classes in `==`, use `eql?` for that. [commit](https://github.com/scottscheapflights/portrayal/commit/9c5a37e4fb91e35d23b22e208344452930452af7)
* Define a protected writer for every keyword - useful when applying changes after `dup`/`clone`.
* Add definition of `#hash` to fix hash equality. Now `hash[object]` will match if `object` is of the same class with the same keywords and values.
* Make #freeze propagate to all keyword values.
* Make #dup and #clone propagate to all keyword values.

## 0.2.0 - 2019-07-03

* It's now possible to specify non-lambda default values, like `default: "foo"`. There is now also a distinction between a proc and a lambda default. Procs are `call`-ed, while lambdas or any other types are returned as-is. In the majority of cases defaults are static values, and there is no need for the performance overhead of making all defaults into anonymous functions. [commit](https://github.com/scottscheapflights/portrayal/commit/a1cc9d0fd40e413210f61b945d37b81c87280fee)

## 0.1.0

First version.
