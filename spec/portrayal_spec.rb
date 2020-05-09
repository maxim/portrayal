RSpec.describe Portrayal do
  let(:target) { Class.new { extend Portrayal } }

  it 'has a version number' do
    expect(Portrayal::VERSION).not_to be nil
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

  shared_examples 'equality based on keywords' do
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
  end

  describe '.new' do
    it 'requires non-optional keywords' do
      target.keyword :foo
      expect { target.new }.to raise_error(ArgumentError, /foo/)
      expect { target.new(foo: 'hi') }.to_not raise_error
    end

    it 'does not require a keyword with a default' do
      target.keyword :two_plus_two, default: proc { 2 + 2 }
      expect { target.new }.to_not raise_error
      expect(target.new.two_plus_two).to eq(4)
    end

    it 'does not require an optional keyword' do
      target.keyword :foo, optional: true
      expect { target.new }.to_not raise_error
      expect(target.new.foo).to be_nil
    end

    it 'does not require an optional keyword with a default' do
      target.keyword :foo, optional: true, default: proc { 2 + 2 }
      expect { target.new }.to_not raise_error
      expect(target.new.foo).to eq(4)
    end

    it 'calls proc defaults' do
      target.keyword :foo, default: proc { 2 + 2 }
      expect(target.new.foo).to eq(4)
    end

    it 'sets lambda defaults without calling them' do
      target.keyword :foo, default: -> { 2 + 2 }
      expect(target.new.foo).to_not eq(4)
      expect(target.new.foo).to be_lambda
    end
  end

  describe '.portrayal' do
    it 'is not there if a keyword has not been declared' do
      expect(target).not_to respond_to(:portrayal)
    end

    it 'is there if a keyword has been declared' do
      target.keyword :foo
      expect(target.portrayal.keywords).to eq([:foo])
      expect(target.portrayal[:foo][:optional]).to eq(false)
      expect(target.portrayal[:foo][:default]).to be_nil
    end

    it 'is there in nested classes with keywords' do
      target.keyword :nested_class do
        keyword :foo
      end

      expect { target::NestedClass }.to_not raise_error
      expect(target::NestedClass.portrayal.keywords).to eq([:foo])
    end

    it 'is there in doubly nested classes with keywords' do
      target.keyword :nested_class_1 do
        keyword :nested_class_2 do
          keyword :foo
        end
      end

      expect { target::NestedClass1::NestedClass2 }.to_not raise_error
      expect(target::NestedClass1::NestedClass2.portrayal.keywords)
        .to eq([:foo])
    end
  end

  describe '.keyword' do
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

    it 'inherits superclass of parent when defining nested classes' do
      child = Class.new(target) { extend Portrayal }
      child.keyword :nested_class do
        keyword :foo
      end

      expect(child.superclass).to eq(target)
      expect(child::NestedClass.superclass).to eq(target)
    end

    it 'allows nested classes to be used as default values' do
      target.keyword :nested_class,
        default: proc { target::NestedClass.new(foo: 'hello') } do
        keyword :foo
      end

      expect(target.new.nested_class.foo).to eq('hello')
    end

    it 'allows defining methods in nested classes' do
      target.keyword :nested_class do
        def foo; 'hello' end
      end

      expect(target::NestedClass.new.foo).to eq('hello')
    end
  end

  describe '#==' do
    let(:equality_method) { :== }

    it_behaves_like 'equality based on keywords'

    it 'ignores class' do
      target.keyword :foo

      target2 = Class.new { extend Portrayal }
      target2.keyword :foo

      object1 = target.new(foo: 'foo')
      object2 = target2.new(foo: 'foo')

      expect(object1.send(equality_method, object2)).to be true
    end
  end

  describe '#eql?' do
    let(:equality_method) { :eql? }

    it_behaves_like 'equality based on keywords'

    it 'compares based on class' do
      target.keyword :foo

      target2 = Class.new { extend Portrayal }
      target2.keyword :foo

      object1 = target.new(foo: 'foo')
      object2 = target2.new(foo: 'foo')

      expect(object1.send(equality_method, object2)).to be false
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
end
