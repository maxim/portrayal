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
          [optional, optional ? [:return, nil] : nil]
        elsif optional == NULL && default != NULL
          [true, [default_strategy(default), default]]
        else
          [optional, optional ? [default_strategy(default), default] : nil]
        end

      @schema[name.to_sym] = { optional: optional, default: default }
    end

    def camelcase(string)
      string.to_s.gsub(/(?:^|_+)([^_])/) { $1.upcase }
    end

    def get_default(name)
      action, value = @schema[name][:default]
      action == :call ? value.call : value
    end

    def default_strategy(value)
      (value.is_a?(Proc) && !value.lambda?) ? :call : :return
    end

    def definition_of_initialize
      init_args =
        @schema
        .map { |name, config|
          if config[:optional]
            "#{name}: self.class.portrayal.get_default(:#{name})"
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

    def definition_of_object_enhancements
      <<-RUBY
      def eql?(other)
        self.class == other.class && self == other
      end

      def ==(other)
        self.class.portrayal.attributes(self) ==
          self.class.portrayal.attributes(other)
      end

      def hash
        [self.class, self.class.portrayal.attributes(self)].hash
      end
      RUBY
    end
  end
end
