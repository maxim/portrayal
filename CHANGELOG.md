This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.9.1 - 2025-01-28

* Add aliases for all redefined methods to suppress method redefinition warnings.
* Add `+''` to mutated strings to suppress Ruby 3.4 frozen string literal warnings.

## 0.9.0 - 2023-05-06

None of these changes should break anything for you, only speed things up, unless you're doing something very weird.

* Rewrite internals to improve runtime performance. No longer depend on `portrayal.attributes`, instead generating ruby code that references keywords literally (much more efficient).
* All attr_readers and other methods such as `eql?`, `==`, `freeze`, etc are now included as a module, rather than class_eval'ed into your class. This lets you use `super` when overriding them.
* Class method `portrayal` now appears when you call `extend Portrayal`, and not after the first `keyword` declaration. (Instance methods are still added upon `keyword`.)
* Remove `portrayal[]` shortcut that accessed `portrayal.schema` (use `portrayal.schema[]` directly instead).
* Remove `portrayal.render_initialize`.
* Add `portrayal.module`, which is the module included in your struct.
* Add `portrayal.render_module_code`, which renders the code for the module.
* Bring back class comparison to `==` (reverses a change in 0.3.0). Upon further research, it seems class comparison is always necessary.
* Methods `==`, `eql?`, `hash`, `initialize_dup`, `initialize_clone`, and `freeze` now operate on @instance @variables, not reader method return values.
* Methods `deconstruct` and `deconstruct_keys` now quietly exclude private/protected keywords.

## 0.8.0 - 2023-01-27

* Add pattern matching support (`#deconstruct` and `#deconstruct_keys`).

## 0.7.1 - 2021-03-22

* Fix default procs' behavior when overriding keywords in subclasses. Portrayal relies on an ordered ruby hash to initialize keywords in the correct order. However, if overriding the same keyword in a subclass (by declaring it again), it didn't move keyword to the bottom of the hash, so this would happen:

    ```ruby
    class Person
      extend Portrayal
      keyword :email, default: nil
    end

    class Employee < Person
      keyword :employee_id
      keyword :email, default: proc { "#{employee_id}@example.com" }
    end

    employee = Employee.new(employee_id: '1234')
    employee.email # => "@example.com"
    ```

    The email is broken because it relies on having employee_id declared before email, but email was already declared first in the superclass. This change fixes situations like this by re-adding the keyword to the bottom of the hash on every re-declaration.

## 0.7.0 - 2020-12-13

* **Breaking change:** Remove `optional` setting. To update find all `optional: true` and change to `default: nil` instead.

* **Breaking change:** Move `self` of default procs to `initialize` context. Before this change, default procs used to be executed naively in class context. Now they can access other keyword readers and instance methods since their `self` is now coming from `initialize`. To update, look through your default procs and replace any reference to current class's methods such as `method_name` with `self.class.method_name`.

## 0.6.0 - 2020-08-10

* Return keyword name from `keyword`, allowing usage such as `private keyword :foo`. [[commit]](https://github.com/maxim/portrayal/commit/9e9db2cafc7eae14789c5b84f70efd18898ace76)

## 0.5.0 - 2020-05-28

* Add option `define` for overriding nested class name. [[commit]](https://github.com/maxim/portrayal/commit/665ad297fb71fcdf5f641c672a457ccbe29e4a49)

## 0.4.0 - 2020-05-16

* Portrayal schema is deep-duped to subclasses. [[commit]](https://github.com/maxim/portrayal/commit/f346483a379ce9fbdece72cde8b0844f2d22b1cd)

## 0.3.1 - 2020-05-11

* Fix the issue introduced in 0.3.0 where `==` and `eql?` were always treating rhs as another portrayal class. [[commit]](https://github.com/maxim/portrayal/commit/f6ec8f373c6582f7e8d8f872d289222e4a58f8f6)

## 0.3.0 - 2020-05-09 (yanked)

* No longer compare classes in `==`, use `eql?` for that. [[commit]](https://github.com/maxim/portrayal/commit/9c5a37e4fb91e35d23b22e208344452930452af7)
* Define a protected writer for every keyword - useful when applying changes after `dup`/`clone`. [[commit]](https://github.com/maxim/portrayal/commit/1c0fa6c6357a09760dae39165e864238d231a08e)
* Add definition of `#hash` to fix hash equality. Now `hash[object]` will match if `object` is of the same class with the same keywords and values. [[commit]](https://github.com/maxim/portrayal/commit/ba9e390ab4aea4733ba084ac273da448e313ea53)
* Make `#freeze` propagate to all keyword values. [[commit]](https://github.com/maxim/portrayal/commit/0a734411a6eac08e2355c4277e09a2a70800d032)
* Make `#dup` and `#clone` propagate to all keyword values. [[commit]](https://github.com/maxim/portrayal/commit/010632d87d81a8d5b5ea5ff27d3d209cc667b0a5)

## 0.2.0 - 2019-07-03

* It's now possible to specify non-lambda default values, like `default: "foo"`. There is now also a distinction between a proc and a lambda default. Procs are `call`-ed, while lambdas or any other types are returned as-is. In the majority of cases defaults are static values, and there is no need for the performance overhead of making all defaults into anonymous functions. [[commit]](https://github.com/maxim/portrayal/commit/a1cc9d0fd40e413210f61b945d37b81c87280fee)

## 0.1.0

First version.
