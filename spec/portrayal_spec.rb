RSpec.describe Portrayal do
  let(:target) { Class.new { extend Portrayal } }

  after { Object.send(:remove_const, :TEST_CLASS__) if defined?(TEST_CLASS__) }

  it 'has a version number' do
    expect(Portrayal::VERSION).not_to be nil
  end

  it 'provides portrayal class method' do
    expect(target).to respond_to(:portrayal)
  end

  it 'matches on class and keywords in hash equality' do
    target.keyword :foo

    target2 = Class.new { extend Portrayal }
    target2.keyword :foo

    object1 = target.new(foo: 'foo')
    object2 = target2.new(foo: 'foo')
    object3 = target.new(foo: 'foo')

    hash = { object1 => '1', object2 => '2' }

    expect(hash[object1]).to eq('1')
    expect(hash[object2]).to eq('2')
    expect(hash[object3]).to eq('1')
  end

  shared_examples 'equality based on class and keywords' do
    it 'compares based on class' do
      target.keyword :foo

      target2 = Class.new { extend Portrayal }
      target2.keyword :foo

      object1 = target.new(foo: 'foo')
      object2 = target2.new(foo: 'foo')

      expect(object1.send(equality_method, object2)).to be false
    end

    it 'compares by keyword names and values' do
      target.keyword :foo
      object1 = target.new(foo: 'foo')
      object2 = target.new(foo: 'foo')
      object3 = target.new(foo: 'bar')

      expect(object1.send(equality_method, object2)).to be true
      expect(object1.send(equality_method, object3)).to be false
    end

    it 'compares by default lambda value' do
      target.keyword :foo, default: -> { 2 + 2 }
      object1 = target.new
      object2 = target.new
      expect(object1.send(equality_method, object2)).to be true
    end

    it 'compares by the result of a default proc' do
      target.keyword :foo, default: proc { 2 + 2 }
      object1 = target.new
      object2 = target.new
      expect(object1.send(equality_method, object2)).to be true
    end

    it 'propagates equality to nested classes' do
      target.keyword :nested_class do
        keyword :foo
      end

      object1 = target.new(nested_class: target::NestedClass.new(foo: 'hello'))
      object2 = target.new(nested_class: target::NestedClass.new(foo: 'hello'))
      object3 = target.new(nested_class: target::NestedClass.new(foo: 'hi'))

      expect(object1.send(equality_method, object2)).to be true
      expect(object1.send(equality_method, object3)).to be false
    end

    it 'falls back on super when compared with non-portrayal classes' do
      target.keyword :foo
      object = target.new(foo: 'value')
      expect(object.send(equality_method, :symbol)).to be false
    end

    it 'falls back on super when compared with other portrayal classes' do
      target.keyword :foo
      target2 = Class.new(target)
      object = target.new(foo: 'value')
      object2 = target2.new(foo: 'value')
      expect(object.send(equality_method, object2)).to be false
    end
  end

  describe '#==' do
    let(:equality_method) { :== }
    it_behaves_like 'equality based on class and keywords'
  end

  describe '#eql?' do
    let(:equality_method) { :eql? }
    it_behaves_like 'equality based on class and keywords'
  end

  describe '.new' do
    it 'requires keywords without defaults' do
      target.keyword :foo
      expect { target.new }.to raise_error(ArgumentError, /foo/)
      expect { target.new(foo: 'hi') }.to_not raise_error
    end

    it 'does not require a keyword with a default' do
      target.keyword :two_plus_two, default: proc { 2 + 2 }
      expect { target.new }.to_not raise_error
      expect(target.new.two_plus_two).to eq(4)
    end

    it 'does not require a keyword with nil default' do
      target.keyword :foo, default: nil
      expect { target.new }.to_not raise_error
      expect(target.new.foo).to be_nil
    end

    it 'calls proc defaults' do
      target.keyword :foo, default: proc { 2 + 2 }
      expect(target.new.foo).to eq(4)
    end

    it 'does not call passed-in procs' do
      target.keyword :foo
      expect(target.new(foo: proc { 2 + 2 }).foo).to_not eq(4)
    end

    it 'provides access to peer keywords when executing proc defaults' do
      target.keyword :foo
      target.keyword :bar, default: proc { "#{foo} world" }
      expect(target.new(foo: 'hello').bar).to eq('hello world')
    end

    it 'provides access to peer defaults when executing proc defaults' do
      target.keyword :foo, default: proc { 2 + 2 }
      target.keyword :bar, default: proc { foo * 2 }
      expect(target.new.bar).to eq(8)
    end

    it 'provides access to instance methods when executing proc defaults' do
      target.class_eval do
        keyword :foo, default: proc { hello_world }
        private def hello_world; 'Hello, World!' end
      end

      expect(target.new.foo).to eq('Hello, World!')
    end

    it 'sets lambda defaults without calling them' do
      target.keyword :foo, default: -> { 2 + 2 }
      expect(target.new.foo).to_not eq(4)
      expect(target.new.foo).to be_lambda
    end
  end

  describe '.keyword' do
    it 'includes instance methods into ancestry' do
      expect { target.keyword(:foo) }
        .to change { target.ancestors[1] }
        .from(Object).to(target.portrayal.module)
    end

    it 'adds keyword to keywords list' do
      target.keyword(:foo)
      expect(target.portrayal.keywords).to eq([:foo])
    end

    it 'adds keyword to keywords list' do
      target.keyword(:foo)
      expect(target.portrayal.keywords).to eq([:foo])
    end

    it 'defines a reader' do
      target.keyword(:foo)
      object = target.new(foo: 'foo')
      expect(object.foo).to eq('foo')
    end

    it 'defines a protected writer' do
      target.keyword(:foo)
      object = target.new(foo: 'foo')
      expect { object.foo = 'bar' }.to raise_error(NoMethodError, /protected/)

      object2 = target.new(foo: 'foo')
      def object2.update(other); other.foo = 'bar' end
      object2.update(object)
      expect(object.foo).to eq('bar')
    end

    it 'adds portrayal to nested class' do
      target.keyword :nested_class do
        keyword :foo
      end

      expect { target::NestedClass }.to_not raise_error
      expect(target::NestedClass.portrayal.keywords).to eq([:foo])
    end

    it 'adds portrayal to doubly nested class' do
      target.keyword :nested_class_1 do
        keyword :nested_class_2 do
          keyword :foo
        end
      end

      expect { target::NestedClass1::NestedClass2 }.to_not raise_error
      expect(target::NestedClass1::NestedClass2.portrayal.keywords)
        .to eq([:foo])
    end

    it 'puts readers into their own modules when nesting' do
      TEST_CLASS__ = target
      class TEST_CLASS__
        keyword :foo, default: 'foo'
        keyword :nested_1, default: proc { Nested1.new } do
          keyword :bar, default: 'bar'
          keyword :nested_2, default: proc { self.class::Nested2.new } do
            keyword :baz, default: 'baz'
          end
        end
      end

      t = target.new
      nt = target::Nested1.new
      nnt = target::Nested1::Nested2.new

      expect(t).to respond_to(:foo)
      expect(t).to respond_to(:nested_1)
      expect(t).to_not respond_to(:bar)
      expect(t).to_not respond_to(:nested_2)
      expect(t).to_not respond_to(:baz)

      expect(nt).to_not respond_to(:foo)
      expect(nt).to_not respond_to(:nested_1)
      expect(nt).to respond_to(:bar)
      expect(nt).to respond_to(:nested_2)
      expect(nt).to_not respond_to(:baz)

      expect(nnt).to_not respond_to(:foo)
      expect(nnt).to_not respond_to(:nested_1)
      expect(nnt).to_not respond_to(:bar)
      expect(nnt).to_not respond_to(:nested_2)
      expect(nnt).to respond_to(:baz)
    end

    it 'inherits superclass of parent when defining nested classes' do
      child = Class.new(target) { extend Portrayal }
      child.keyword :nested_class do
        keyword :foo
      end

      expect(child.superclass).to eq(target)
      expect(child::NestedClass.superclass).to eq(target)
    end

    it 'allows nested classes to be used as default values' do
      TEST_CLASS__ = target
      class TEST_CLASS__
        keyword :nested, default: proc { Nested.new(foo: 'hello') } do
          keyword :foo
        end
      end

      expect(TEST_CLASS__.new.nested.foo).to eq('hello')
    end

    it 'does not use wrong Default, Schema and NULL consts when they exist' do
      TEST_CLASS__ = target
      class TEST_CLASS__
        class Default; end
        class Schema; NULL = 'something' end
        keyword :foo, default: 'foo'
        keyword :bar, default: nil
        keyword :baz
      end

      expect(TEST_CLASS__.new(baz: 1).foo).to eq('foo')
      expect(TEST_CLASS__.new(baz: 1).bar).to eq(nil)
      expect(TEST_CLASS__.new(baz: 1).baz).to eq(1)
    end

    it 'allows defining methods in nested classes' do
      target.keyword :nested_class do
        def foo; 'hello' end
      end

      expect(target::NestedClass.new.foo).to eq('hello')
    end

    it 'allows overriding names of nested classes' do
      target.keyword :things, define: 'Thing' do
        keyword :foo, default: 'foo'
      end

      expect(target::Thing.new.foo).to eq('foo')
    end

    it 'returns name of the defined reader' do
      value = target.keyword :foo
      expect(value).to eq(:foo)
    end

    it 're-appends keyword to the end of schema on every redeclaration' do
      target.keyword :foo
      target.keyword :bar
      target.keyword :foo, default: proc { bar }
      expect(target.new(bar: 'bar').foo).to eq('bar')
    end

    it 'adds keyword readers into a module' do
      target.class_eval do
        keyword :foo, default: 'from module'
        def foo; super + ' with override' end
      end

      expect(target.new.foo).to eq('from module with override')
    end
  end

  describe '#hash' do
    it 'is the same for objects of the same class and keywords' do
      target.keyword :foo
      object1 = target.new(foo: 'foo')
      object2 = target.new(foo: 'foo')
      expect(object1.hash).to eq(object2.hash)
    end

    it 'is different for objects of different class regardless of keywords' do
      target.keyword :foo

      target2 = Class.new { extend Portrayal }
      target2.keyword :foo

      object1 = target.new(foo: 'foo')
      object2 = target2.new(foo: 'foo')

      expect(object1.hash).not_to eq(object2.hash)
    end

    it 'is different for objects with different keyword values' do
      target.keyword :foo
      object1 = target.new(foo: 'foo')
      object2 = target.new(foo: 'bar')
      expect(object1.hash).not_to eq(object2.hash)
    end
  end

  describe '#freeze' do
    it 'prevents modification of the frozen object' do
      target.keyword :foo
      object = target.new(foo: 'foo')
      object.freeze

      expect { object.instance_variable_set('@foo', 'bar') }
        .to raise_error(/frozen/)
    end

    it 'prevents modifications of nested objects' do
      target.keyword :array
      object = target.new(array: %w[a])
      object.freeze
      expect { object.array << 'b' }.to raise_error(/frozen/)
    end
  end

  describe '#dup' do
    it 'copies the object' do
      target.keyword :foo
      object = target.new(foo: 'foo')
      copy = object.dup
      expect(copy.object_id).not_to eq(object.object_id)

      copy.instance_variable_set('@foo', 'bar')
      expect(object.foo).to eq('foo')
      expect(copy.foo).to eq('bar')
    end

    it 'copies keyword values' do
      target.keyword :array
      object = target.new(array: ['a'])
      copy = object.dup
      object.array << 'b'
      copy.array << 'c'
      expect(object.array).to eq(%w[a b])
      expect(copy.array).to eq(%w[a c])
    end

    it 'does not copy the frozen state of the object' do
      target.keyword :foo
      object = target.new(foo: 'foo')
      object.freeze
      copy = object.dup
      expect(copy).not_to be_frozen
    end

    it 'does not copy the frozen state of keyword values' do
      target.keyword :array
      object = target.new(array: ['a'])
      object.freeze
      copy = object.dup
      expect(copy.array).not_to be_frozen
    end
  end

  describe '#clone' do
    it 'copies the object' do
      target.keyword :foo
      object = target.new(foo: 'foo')
      copy = object.clone
      expect(copy.object_id).not_to eq(object.object_id)

      copy.instance_variable_set('@foo', 'bar')
      expect(object.foo).to eq('foo')
      expect(copy.foo).to eq('bar')
    end

    it 'copies keyword values' do
      target.keyword :array
      object = target.new(array: ['a'])
      copy = object.clone
      object.array << 'b'
      copy.array << 'c'
      expect(object.array).to eq(%w[a b])
      expect(copy.array).to eq(%w[a c])
    end

    it 'copies the frozen state of the object' do
      target.keyword :foo
      object = target.new(foo: 'foo')
      object.freeze
      copy = object.clone
      expect(copy).to be_frozen
    end

    it 'copies the frozen state of keyword values' do
      target.keyword :array
      object = target.new(array: ['a'])
      object.freeze
      copy = object.clone
      expect(copy.array).to be_frozen
    end
  end

  describe '#deconstruct' do
    it 'returns array of keyword values' do
      target.keyword :foo
      target.keyword :bar
      object = target.new(foo: 'foo', bar: 'bar')
      expect(object.deconstruct).to eq(%w[foo bar])
    end

    it 'returns values in the correct order in a subclass' do
      target.keyword :foo
      target.keyword :bar
      target2 = Class.new(target)
      target2.keyword :baz
      object = target2.new(baz: 'baz', foo: 'foo', bar: 'bar')
      expect(object.deconstruct).to eq(%w[foo bar baz])
    end

    it 'returns values by calling reader methods' do
      target.keyword :num
      object = target.new(num: 1)
      def object.num; 2 end
      expect(object.deconstruct).to eq([2])
    end

    it 'silently excludes private and protected readers' do
      target.class_eval do
        private   keyword :priv
        protected keyword :prot
        public    keyword :publ
      end

      object = target.new(priv: 'priv', prot: 'prot', publ: 'publ')
      expect(object.deconstruct).to eq(['publ'])
    end
  end

  describe '#deconstruct_keys' do
    it 'returns hash of key/value pairs' do
      target.keyword :foo
      target.keyword :bar
      object = target.new(foo: 'foo', bar: 'bar')
      expect(object.deconstruct_keys(nil)).to eq({foo: 'foo', bar: 'bar'})
    end

    it 'returns filtered hash of key/value pairs' do
      target.keyword :foo
      target.keyword :bar
      object = target.new(foo: 'foo', bar: 'bar')
      expect(object.deconstruct_keys([:bar])).to eq(bar: 'bar')
    end

    it 'does not error-out on non-recognized keys' do
      target.keyword :foo
      object = target.new(foo: 'foo')
      expect { object.deconstruct_keys([:x]) }.to_not raise_error
      expect(object.deconstruct_keys([:x])).to eq({})
    end

    it 'returns empty hash when empty array is given' do
      target.keyword :foo
      object = target.new(foo: 'foo')
      expect(object.deconstruct_keys([])).to eq({})
    end

    it 'returns values by calling reader methods' do
      target.keyword :num
      object = target.new(num: 1)
      def object.num; 2 end
      expect(object.deconstruct_keys(nil)).to eq(num: 2)
      expect(object.deconstruct_keys([:num])).to eq(num: 2)
    end

    it 'silently excludes private and protected readers' do
      target.class_eval do
        private   keyword :priv
        protected keyword :prot
        public    keyword :publ
      end

      object = target.new(priv: 'priv', prot: 'prot', publ: 'publ')
      expect(object.deconstruct_keys([:priv, :prot, :publ])).to eq(publ: 'publ')
      expect(object.deconstruct_keys(nil)).to eq(publ: 'publ')
    end
  end

  describe 'subsclassing' do
    it 'allows subclass to add more keywords' do
      target.keyword :foo
      target2 = Class.new(target)
      target2.keyword :bar

      object = target2.new(foo: 'foo', bar: 'bar')
      expect(object.foo).to eq('foo')
      expect(object.bar).to eq('bar')
    end

    it 'does not break subclassing when some defaults are procs and lambdas' do
      target.keyword :foo, default: -> { 'foo' }
      target.keyword :bar, default: proc { 'bar' }
      target2 = Class.new(target)
      target2.keyword :baz

      object = target2.new(baz: 'baz')
      expect(object.foo).to be_lambda
      expect(object.bar).to eq('bar')
    end

    it 'creates copies of defaults upon subclassing' do
      target.keyword :foo, default: []
      target2 = Class.new(target)

      object1 = target.new
      object2 = target2.new

      object1.foo << 1
      object2.foo << 2

      expect(object1.foo).to eq([1])
      expect(object2.foo).to eq([2])
    end

    it 'does not modify superclass module when adding keywords to subclass' do
      target.keyword :foo
      target2 = Class.new(target)
      target2.keyword :bar
      expect {
        target.new(foo: 'foo', bar: 'bar')
      }.to raise_error(ArgumentError, /bar/)
    end

    it 'duplicates module upon inheritance' do
      target2 = Class.new(target)
      target2.portrayal.module.module_eval("def hello; 'hello' end")
      expect(target.new).to_not respond_to(:hello)
      expect(target2.new.hello).to eq('hello')
    end
  end
end
