module Portrayal
  class Default
    attr_reader :value

    def initialize(value)
      @value = value
      @callable = value.is_a?(Proc) && !value.lambda?
    end

    def call?; @callable end
    def initialize_dup(src); super; @value = src.value.dup end
  end
end
