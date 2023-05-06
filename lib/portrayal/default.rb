class Portrayal::Default
  attr_reader :value
  protected :value

  def initialize(value)
    @value = value
    @callable = value.is_a?(Proc) && !value.lambda?
  end

  def call(obj); @callable ? obj.instance_exec(&value) : value end
  def initialize_dup(src); @value = src.value.dup; super end
end
