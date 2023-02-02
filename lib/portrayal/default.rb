class Portrayal::Default
  protected attr_reader :value

  def initialize(value)
    @value = value
    @callable = value.is_a?(Proc) && !value.lambda?
  end

  def get(obj); @callable ? obj.instance_exec(&value) : value end
  def initialize_dup(src); @value = src.value.dup; super end
end
