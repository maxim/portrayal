This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2019-07-03

### Changed

* It's now possible to specify non-lambda default values, like `default: "foo". There is now also a distinction between a proc and a lambda default. Procs are `call`-ed, while lambdas or any other types are returned as-is. In the majority of cases defaults are static values, and there is no need for the performance overhead of making all defaults into anonymous functions.

## [0.1.0]

First version.
