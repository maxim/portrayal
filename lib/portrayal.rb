require 'portrayal/version'
require 'portrayal/schema'

module Portrayal
  NULL = :_portrayal_value_not_set

  def keyword(name, default: NULL, define: nil, &block)
    unless respond_to?(:portrayal)
      class << self
        attr_reader :portrayal
        def inherited(base)
          base.instance_variable_set('@portrayal', portrayal.dup)
        end
      end

      @portrayal = Schema.new
      class_eval(Schema::DEFINITION_OF_OBJECT_ENHANCEMENTS)
    end

    attr_accessor name
    protected "#{name}="

    portrayal.add_keyword(name, default)
    class_eval(portrayal.definition_of_initialize)

    if block_given?
      kw_class = Class.new(superclass) { extend Portrayal }
      const_set(define || portrayal.camelize(name), kw_class).class_eval(&block)
    end

    name
  end
end
