RSpec.describe Portrayal do
  let(:target) { Class.new { extend Portrayal } }

  it 'has a version number' do
    expect(Portrayal::VERSION).not_to be nil
  end

  it 'requires declared keyword' do
    target.keyword :foo
    expect { target.new }.to raise_error(ArgumentError, /foo/)
    expect { target.new(foo: 'hi') }.to_not raise_error
  end

  it 'allows keyword to have a default, which makes it optional' do
    target.keyword :two_plus_two, default: proc { 2 + 2 }
    expect { target.new }.to_not raise_error
    expect(target.new.two_plus_two).to eq(4)
  end

  it 'allows keyword to be optional' do
    target.keyword :foo, optional: true
    expect { target.new }.to_not raise_error
    expect(target.new.foo).to be_nil
  end

  it 'allows keyword to be optional with a default' do
    target.keyword :foo, optional: true, default: proc { 2 + 2 }
    expect { target.new }.to_not raise_error
    expect(target.new.foo).to eq(4)
  end

  it 'calls proc defaults' do
    target.keyword :foo, default: proc { 2 + 2 }
    expect(target.new.foo).to eq(4)
  end

  it 'returns lambda defaults' do
    target.keyword :foo, default: -> { 2 + 2 }
    expect(target.new.foo).to_not eq(4)
    expect(target.new.foo).to be_lambda
  end

  it 'defines equality in terms of keyword names and values' do
    target.keyword :foo
    object1 = target.new(foo: 'foo')
    object2 = target.new(foo: 'foo')
    object3 = target.new(foo: 'bar')

    expect(object1).to eq(object2)
    expect(object1).to_not eq(object3)
  end

  it 'defines equality in terms of default values when default is lambda' do
    target.keyword :foo, default: -> { 2 + 2 }
    object1 = target.new
    object2 = target.new
    expect(object1).to eq(object2)
  end

  it 'defines equality in terms of default values when default is proc' do
    target.keyword :foo, default: proc { 2 + 2 }
    object1 = target.new
    object2 = target.new
    expect(object1).to eq(object2)
  end

  it 'provides schema at class level' do
    target.keyword :foo
    expect(target.portrayal.keywords).to eq([:foo])
    expect(target.portrayal[:foo][:optional]).to eq(false)
    expect(target.portrayal[:foo][:default]).to be_nil
  end

  it 'declares portrayal class for nested keywords' do
    target.keyword :nested_class do
      keyword :foo
    end

    expect { target::NestedClass }.to_not raise_error
    expect(target::NestedClass.portrayal.keywords).to eq([:foo])
  end

  it 'declares portrayal class for doubly nested keywords' do
    target.keyword :nested_class_1 do
      keyword :nested_class_2 do
        keyword :foo
      end
    end

    expect { target::NestedClass1::NestedClass2 }.to_not raise_error
    expect(target::NestedClass1::NestedClass2.portrayal.keywords).to eq([:foo])
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

  it 'delegates to equality of nested classes' do
    target.keyword :nested_class do
      keyword :foo
    end

    object1 = target.new(nested_class: target::NestedClass.new(foo: 'hello'))
    object2 = target.new(nested_class: target::NestedClass.new(foo: 'hello'))
    object3 = target.new(nested_class: target::NestedClass.new(foo: 'hi'))

    expect(object1).to eq(object2)
    expect(object1).to_not eq(object3)
  end
end
