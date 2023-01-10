![RSpec](https://github.com/maxim/portrayal/workflows/RSpec/badge.svg)

# Portrayal

Inspired by:

  - Andrew Kozin's [dry-initializer](https://github.com/dry-rb/dry-initializer)
  - Piotr Solnica's [virtus](https://github.com/solnic/virtus)
  - Everything [Michel Martens](https://github.com/soveran)

Portrayal is a minimalist gem (~130 loc, no dependencies) for building struct-like classes. It provides a small yet powerful step up from plain ruby with its one and only `keyword` method.

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

### Schema

Every class that has at least one keyword defined in it automatically receives a class method called `portrayal`. This method is a schema of your object with some additional helpers.

#### `portrayal.keywords`

Get all keyword names.

```ruby
Address.portrayal.keywords # => [:street, :city, :postcode, :country]
```

#### `portrayal.attributes`

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

The fact that we keep these portrayal structs read-only (nothing stops you from adding writers, but I will personally frown upon you), all of the responsibility of building them shifts into constructors. This is a good thing, because good constructors clearly define their dependencies, as well as giving us ample room for performing coercion.

```ruby
class Address < ApplicationStruct
  class << self
    def from_form(params)
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

Good constructors can also depend on one another to successively break down dependnecies into essential parts. This is similar to how in functional languages one can use recursion and pattern matching.

```ruby
class Email < ApplicationStruct
  class << self
    def from_publishing_service_json(json)
      subject, header, body, footer = *JSON.parse(json)
      from_parts(subject: subject, header: header, body: body, footer: footer)
    end

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

#### No Reinventing The Wheel

Portrayal leans on Ruby to take care of enforcing required keyword arguments, and setting keyword argument defaults. It actually generates standard ruby keyword arguments for you behind the scenes. You can even see the code by checking `YourClass.portrayal.definition_of_initialize`.

```irb
Address.portrayal.definition_of_initialize
=> "def initialize(street:,city:,postcode:,country: self.class.portrayal.call_default(:country)); @street = street; @city = city; @postcode = postcode; @country = country end"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/maxim/portrayal. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.txt).

## Code of Conduct

Everyone interacting in the Portrayal project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/maxim/portrayal/blob/main/CODE_OF_CONDUCT.md).
