module Portrayal
  class Schema
    attr_reader :schema

    def initialize
      @schema = {}
      @equality_defined = false
    end

    def [](name)
      @schema[name]
    end

    def keywords
      @schema.keys
    end

    def attributes(object)
      Hash[
        object.class.portrayal.keywords.map { |key| [key, object.send(key)] }
      ]
    end

    def add_keyword(name, optional, default)
      optional, default =
        if optional == NULL && default == NULL
          [false, nil]
        elsif optional != NULL && default == NULL
          [optional, optional ? -> { nil } : nil]
        elsif optional == NULL && default != NULL
          [true, default]
        else
          [optional, optional ? default : nil]
        end

      @schema[name.to_sym] = { optional: optional, default: default }
    end

    def camelcase(string)
      string.to_s.gsub(/(?:^|_+)([^_])/) { $1.upcase }
    end

    def call_default(name)
      @schema[name][:default].call
    end

    def definition_of_initialize
      init_args =
        @schema
        .map { |name, config|
          if config[:optional]
            "#{name}: self.class.portrayal.call_default(:#{name})"
          else
            "#{name}:"
          end
        }
        .join(',')

      init_assignments =
        @schema
        .keys
        .map { |name| "@#{name} = #{name}" }
        .join('; ')

      "def initialize(#{init_args}); #{init_assignments} end"
    end

    def definition_of_equality
      <<-RUBY
      def ==(other)
        self.class == other.class &&
          self.class.portrayal.attributes(self) ==
          self.class.portrayal.attributes(other)
      end

      alias eql? ==
      RUBY
    end

    def equality_defined?
      @equality_defined
    end

    def mark_equality_defined
      @equality_defined = true
    end
  end
end
