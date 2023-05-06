[![Gem Version](https://badge.fury.io/rb/portrayal.svg)](https://badge.fury.io/rb/portrayal) ![RSpec](https://github.com/maxim/portrayal/workflows/RSpec/badge.svg)

# Portrayal

Inspired by:

  - Andrew Kozin's [dry-initializer](https://github.com/dry-rb/dry-initializer)
  - Piotr Solnica's [virtus](https://github.com/solnic/virtus)
  - Everything [Michel Martens](https://github.com/soveran)

Portrayal is a minimalist gem (~110 loc, no dependencies) for building struct-like classes. It provides a small yet powerful step up from plain ruby with its one and only `keyword` method.

```ruby
class Person < MySuperClass
  extend Portrayal

  keyword :name
  keyword :age, default: nil
  keyword :favorite_fruit, default: 'feijoa'

  keyword :address do
    keyword :street
    keyword :city

    def text
      "#{street}, #{city}"
    end
  end
end
```

When you call `keyword`:

* It defines an `attr_reader`
* It defines a protected `attr_writer`
* It defines `initialize`
* It defines `==` and `eql?`
* It defines `#hash` for hash equality
* It defines `#dup` and `#clone` that propagate to all keyword values
* It defines `#freeze` that propagates to all keyword values
* It defines `#deconstruct` and `#deconstruct_keys` for pattern matching
* It creates a nested class when you supply a block
* It inherits parent's superclass when creating a nested class

The code above produces almost exactly the following ruby. There's a lot of boilerplate here we didn't have to type.

```ruby
class Person < MySuperClass
  attr_accessor :name, :age, :favorite_fruit, :address
  protected :name=, :age=, :favorite_fruit=, :address=

  def initialize(name:, age: nil, favorite_fruit: 'feijoa', address:)
    @name = name
    @age = age
    @favorite_fruit = favorite_fruit
    @address = address
  end

  def eql?(other)
    self.class == other.class && self == other
  end

  def ==(other)
    { name: name, age: age, favorite_fruit: favorite_fruit, address: address } ==
      { name: other.name, age: other.age, favorite_fruit: other.favorite_fruit, address: other.address }
  end

  def hash
    [ self.class, { name: name, age: age, favorite_fruit: favorite_fruit, address: address } ].hash
  end

  def freeze
    name.freeze
    age.freeze
    favorite_fruit.freeze
    address.freeze
    super
  end

  def deconstruct
    [ name, age, favorite_fruit, address ]
  end

  def deconstruct_keys(*)
    { name: name, age: age, favorite_fruit: favorite_fruit, address: address }
  end

  def initialize_dup(source)
    @name = source.name.dup
    @age = source.age.dup
    @favorite_fruit = source.favorite_fruit.dup
    @address = source.address.dup
    super
  end

  def initialize_clone(source)
    @name = source.name.clone
    @age = source.age.clone
    @favorite_fruit = source.favorite_fruit.clone
    @address = source.address.clone
    super
  end

  class Address < MySuperClass
    attr_accessor :street, :city
    protected :street=, :city=

    def initialize(street:, city:)
      @street = street
      @city = city
    end

    def text
      "#{street}, #{city}"
    end

    def eql?(other)
      self.class == other.class && self == other
    end

    def ==(other)
      { street: street, city: city } == { street: other.street, city: other.city }
    end

    def hash
      [ self.class, { street: street, city: city } ].hash
    end

    def freeze
      street.freeze
      city.freeze
      super
    end

    def deconstruct
      [ street, city ]
    end

    def deconstruct_keys(*)
      { street: street, city: city }
    end

    def initialize_dup(source)
      @street = source.street.dup
      @city = source.city.dup
      super
    end

    def initialize_clone(source)
      @street = source.street.clone
      @city = source.city.clone
      super
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'portrayal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install portrayal

## Usage

The recommended way of using this gem is to build your own superclass extended with Portrayal. For example, if you're in Rails, you could do something like this:

```ruby
class ApplicationStruct
  include ActiveModel::Model
  extend Portrayal
end
```

Now you can inherit it when building domain objects.

```ruby
class Address < ApplicationStruct
  keyword :street
  keyword :city
  keyword :postcode
  keyword :country, default: nil
end
```

Possible use cases for these objects include, but are not limited to:

- Decorator/presenter objects
- Tableless models
- Objects serializable for 3rd party APIs
- Objects serializable for React components

### Defaults

When specifying default, there's a difference between procs and lambda.

```ruby
keyword :foo, default: proc { 2 + 2 } # => Will call this proc and return 4
keyword :foo, default: -> { 2 + 2 }   # => Will return this lambda itself
```

Any other value works as normal.

```ruby
keyword :foo, default: 4
```

#### Default procs

Default procs are executed as though they were called in your class's `initialize`, so they have access to other keywords and instance methods.

```ruby
keyword :name
keyword :greeting, default: proc { "Hello, #{name}" }
```

Defaults can also use results of other defaults.

```ruby
keyword :four,  default: proc { 2 + 2 }
keyword :eight, default: proc { four * 2 }
```

Or instance methods of the class.

```ruby
keyword :id, default: proc { generate_id }

private

def generate_id
  SecureRandom.alphanumeric
end
```

Note: The order in which you declare keywords matters when specifying defaults that depend on other keywords. This will not have the desired effect:

```ruby
keyword :greeting, default: proc { "Hello, #{name}" }
keyword :name
```

### Nested Classes

When you pass a block to a keyword, it creates a nested class named after camelized keyword name.

```ruby
class Person
  extend Portrayal

  keyword :address do
    keyword :street
  end
end
```

The above block created class `Person::Address`.

If you want to change the name of the created class, use the option `define`.

```ruby
class Person
  extend Portrayal

  keyword :visited_countries, define: 'Country' do
    keyword :name
  end
end
```

This defines `Person::Country`, while the accessor remains `visited_countries`.

### Subclassing

Portrayal supports subclassing.

```ruby
class Person
  extend Portrayal
  
  class << self
    def from_contact(contact)
      new name:    contact.full_name,
          address: contact.address.to_s,
          email:   contact.email
    end
  end
  
  keyword :name
  keyword :address
  keyword :email, default: nil
end
```

```ruby
class Employee < Person
  keyword :employee_id
  keyword :email, default: proc { "#{employee_id}@example.com" }
end
```

Now when you call `Employee.new` it will accept keywords of both superclass and subclass. You can also see how `email`'s default is overridden in the subclass.

However, if you try calling `Employee.from_contact(contact)` it will error out, because that constructor doesn't set an `employee_id` required in the subclass. You can remedy that with a small change.

```ruby
    def from_contact(contact, **kwargs)
      new name:    contact.full_name,
          address: contact.address.to_s,
          email:   contact.email,
          **kwargs
    end
```

If you add `**kwargs` to `Person.from_contact` and pass them through to new, then you are now able to call `Employee.from_contact(contact, employee_id: 'some_id')`

### Pattern Matching

If your Ruby has pattern matching, you can pattern match portrayal objects. Both array- and hash-style matching are supported.

```ruby
class Point
  extend Portrayal

  keyword :x
  keyword :y
end

point = Point.new(x: 5, y: 10)

case point
in 5, 10
  'matched'
else
  'did not match'
end # => "matched"

case point
in x:, y: 10
  'matched'
else
  'did not match'
end # => "matched"
```

### Introspection

Every class that extends Portrayal receives a method called `portrayal`. This method is a schema of your object with some additional helpers.

#### `portrayal.keywords`

Get all keyword names.

```ruby
Address.portrayal.keywords # => [:street, :city, :postcode, :country]
```

#### `portrayal.attributes(object)`

Get all names + values as a hash.

```ruby
address = Address.new(street: '34th st', city: 'NYC', postcode: '10001', country: 'USA')
Address.portrayal.attributes(address) # => {street: '34th st', city: 'NYC', postcode: '10001', country: 'USA'}
```

#### `portrayal.schema`

Get everything portrayal knows about your keywords in one hash.

```ruby
Address.portrayal.schema # => {:street=>nil, :city=>nil, :postcode=>nil, :country=><Portrayal::Default @value=nil @callable=false>}
```

## Philosophy

Portrayal steps back from things like type enforcement, coercion, and writer methods in favor of read-only structs, and good old constructors.

#### Good Constructors

Since a portrayal object is read-only (nothing stops you from adding writers, but I will personally frown upon you), you must set all its values in a constructor. This is a good thing, because it lets us study, coerce, and validate all the passed-in arguments in one convenient place. We're assured that once instantiated, the object is valid. And of course we can have multiple constructors if needed. They serve as adapters for different kinds of input.

```ruby
class Address < ApplicationStruct
  class << self
    def from_form(params)
      raise ArgumentError, 'invalid postcode' unless postcode =~ /\A\d+\z/

      new \
        street:   params[:street].to_s,
        city:     params[:city].to_s,
        postcode: params[:postcode].to_i,
        country:  params[:country] || 'USA'
    end

    def from_some_service_api_object(object)
      new \
        street:   "#{object.houseNumber} #{object.streetName}",
        city:     object.city,
        postcode: object.zipCode,
        counry:   object.countryName != '' ? object.countryName : 'USA'
    end
  end

  keyword :street
  keyword :city
  keyword :postcode
  keyword :country, default: nil
end
```

Good constructors can depend on one another to successively convert arguments into keywords. This is similar to how in functional languages one can use recursion and pattern matching.

```ruby
class Email < ApplicationStruct
  class << self
    # Extract parts of an email from JSON, and kick it over to from_parts.
    def from_publishing_service_json(json)
      subject, header, body, footer = *JSON.parse(json)
      from_parts(subject: subject, header: header, body: body, footer: footer)
    end

    # Combine parts into the final keywords: subject and body.
    def from_parts(subject:, header:, body:, footer:)
      new(subject: subject, body: "#{header}#{body}#{footer}")
    end
  end

  keyword :subject
  keyword :body
end
```

If these contructors need more space to grow in complexity, they can be extracted into their own files.

```
address/
  from_form_constructor.rb
address.rb
```

```ruby
class Address < ApplicationStruct
  class << self
    def from_form(params)
      self::FromFormConstructor.new(params).call
    end
  end

  keyword :street
  keyword :city
  keyword :postcode
  keyword :country, default: nil
end
```

If a particular constructor doesn't belong on your object (i.e. a 3rd party module is responsible for parsing its own data and producing your object) — you don't need to have a special constructor. Remember that each portrayal object comes with `.new`, which accepts every keyword directly. Let the module do all the parsing on its side and call `.new` with final values.

#### No Reinventing The Wheel

Portrayal leans on Ruby's built-in features as much as possible. For initialize and default values it generates standard ruby keyword arguments. You can see all the code portrayal generates for your objects by running `YourClass.portrayal.render_methods`.

```irb
[1] pry(main)> puts Address.portrayal.render_methods
attr_accessor :street, :city, :postcode, :country
protected :street=, :city=, :postcode=, :country=
def initialize(street:, city:, postcode:, country: self.class.portrayal.schema[:country]); @street = street.is_a?(::Portrayal::Default) ? street.(self) : street; @city = city.is_a?(::Portrayal::Default) ? city.(self) : city; @postcode = postcode.is_a?(::Portrayal::Default) ? postcode.(self) : postcode; @country = country.is_a?(::Portrayal::Default) ? country.(self) : country end
def hash; [self.class, {street: @street, city: @city, postcode: @postcode, country: @country}].hash end
def ==(other); self.class == other.class && @street == other.instance_variable_get('@street') && @city == other.instance_variable_get('@city') && @postcode == other.instance_variable_get('@postcode') && @country == other.instance_variable_get('@country') end
alias eql? ==
def freeze; @street.freeze; @city.freeze; @postcode.freeze; @country.freeze; super end
def initialize_dup(src); @street = src.instance_variable_get('@street').dup; @city = src.instance_variable_get('@city').dup; @postcode = src.instance_variable_get('@postcode').dup; @country = src.instance_variable_get('@country').dup; super end
def initialize_clone(src); @street = src.instance_variable_get('@street').clone; @city = src.instance_variable_get('@city').clone; @postcode = src.instance_variable_get('@postcode').clone; @country = src.instance_variable_get('@country').clone; super end
def deconstruct
  public_syms = [:street, :city, :postcode, :country].select { |s| self.class.public_method_defined?(s) }
  public_syms.map { |s| public_send(s) }
end
def deconstruct_keys(keys)
  filtered_keys = [:street, :city, :postcode, :country].select {|s| self.class.public_method_defined?(s) }
  filtered_keys &= keys if Array === keys
  Hash[filtered_keys.map { |k| [k, public_send(k)] }]
end
```

#### Implementation decisions

Here are some key architectural decisions that took a lot of thinking. If you have good counter-arguments please make an issue, or contact me on [mastodon](https://ruby.social/@maxim) / [twitter](https://twitter.com/hakunin).

1. **Why do methods `#==`, `#eql?`, `#hash` rely on @instance @variables instead of calling reader methods?**  
   Portrayal makes a careful assumption on what most people would expect from object equality: a comparison of type and runtime state (which is what instance variables are). Portrayal avoids comparing object structure and method return values, because it's too situational whether they should participate in equality or not. If you have such a situation, you're welcome to redefine `==` in your class.
2. **Why do methods `clone` and `dup` copy @instance @variables instead of calling reader methods?**  
   As with the reason for `==`, when we clone an object, we want to clone its type and runtime state. Not the artifacts of its structure. It's too presumptious for a clone to assume that method outputs are authoritative. If objects are written deterministically, then by cloning their inner runtime state we should get the same reader method outputs anyway. If you are doing something else, you're welcome to redefine `initialize_clone`/`initialize_dup` in your class.
3. **Why does pattern matching (`deconstruct`/`deconstruct_keys`) call reader methods rather than reading @instance @variables?**  
   Unlike equality or object replication, in case of pattern matching we're no longer trying to figure out object's identity, rather we are now an external caller working directly with the values that an object exposes. That's why portrayal lets pattern matching depend on reader methods that get to decide how to expose data outwardly, while making a conscious effort to exclude private and protected readers. You're welcome to override `deconstruct` and `deconstruct_keys` in your class if you'd like to do something different.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/maxim/portrayal. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.txt).

## Code of Conduct

Everyone interacting in the Portrayal project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/maxim/portrayal/blob/main/CODE_OF_CONDUCT.md).
