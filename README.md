# Portrayal

Inspired by:

  - Andrew Kozin's [dry-initializer](https://github.com/dry-rb/dry-initializer)
  - Piotr Solnica's [virtus](https://github.com/solnic/virtus)
  - Everything [Michel Martens](https://github.com/soveran)

Portrayal is a minimalist gem (~120 loc, no dependencies) for building struct-like classes. It provides a small yet powerful step up from plain ruby with its one and only `keyword` method.

```ruby
class Person < MySuperClass
  extend Portrayal

  keyword :name
  keyword :age, optional: true
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
* It defines `initialize`
* It defines `==` and `eql?`
* It creates a nested class when you supply a block
* It inherits parent's superclass when creating a nested class

The code above produces almost exactly the following ruby. There's a lot of boilerplate here we didn't have to type.

```ruby
class Person < MySuperClass
  attr_reader :name, :age, :favorite_fruit, :address

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

  class Address < MySuperClass
    attr_reader :street, :city

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
  keyword :country, optional: true
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
Address.portrayal.schema # => {:street=>{:optional=>false, :default=>nil}, :city=>{:optional=>false, :default=>nil}, :postcode=>{:optional=>false, :default=>nil}, :country=>{:optional=>true, :default=>[:return, nil]}}
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
  keyword :country, optional: true
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
  keyword :country, optional: true
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

Bug reports and pull requests are welcome on GitHub at https://github.com/scottscheapflights/portrayal. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.txt).

## Code of Conduct

Everyone interacting in the Portrayal project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scottscheapflights/portrayal/blob/master/CODE_OF_CONDUCT.md).
