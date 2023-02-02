require 'portrayal/version'
require 'portrayal/schema'

module Portrayal
  attr_reader :portrayal
  def self.extended(c); c.instance_variable_set(:@portrayal, Schema.new) end
  def inherited(c); c.instance_variable_set(:@portrayal, portrayal.dup) end

  def keyword(name, default: Schema::NULL, define: nil, &block)
    include Portrayal::Methods if portrayal.empty?
    attr_accessor name
    protected "#{name}="
    portrayal.add_keyword(name, default)
    class_eval(portrayal.render_initialize)

    if block_given?
      nested = Class.new(superclass) { extend ::Portrayal }
      const_set(define || portrayal.camelize(name), nested).class_eval(&block)
    end
    name
  end
end
