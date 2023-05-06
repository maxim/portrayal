require 'portrayal/version'
require 'portrayal/schema'

module Portrayal
  attr_reader :portrayal
  def self.extended(c); c.instance_variable_set(:@portrayal, Schema.new) end

  def inherited(c)
    c.instance_variable_set(:@portrayal, portrayal.dup)
    c.include(c.portrayal.module)
  end

  def keyword(name, default: Schema::NULL, define: nil, &block)
    include portrayal.module
    portrayal.add_keyword(name, default)
    return name unless block_given?
    nested = Class.new(superclass) { extend ::Portrayal }
    const_set(define || portrayal.camelize(name), nested).class_eval(&block)
    name
  end
end
