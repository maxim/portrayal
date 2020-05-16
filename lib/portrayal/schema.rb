module Portrayal
  class Schema
    attr_reader :schema

    def initialize
      @schema = {}
    end

    def keywords; @schema.keys end
    def [](name); @schema[name] end

    def attributes(object)
      Hash[object.class.portrayal.keywords.map { |k| [k, object.send(k)] }]
    end

    def add_keyword(name, optional, default)
      optional, default =
        case [optional == NULL, default == NULL]
        when [true,  true];  [false, nil]
        when [false, true];  [optional, optional ? [:return, nil] : nil]
        when [true,  false]; [true, [default_strategy(default), default]]
        else; [optional, optional ? [default_strategy(default), default] : nil]
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
      init_args = @schema.map { |name, config|
        config[:optional] ?
          "#{name}: self.class.portrayal.get_default(:#{name})" : "#{name}:"
      }.join(',')

      init_assigns = @schema.keys.map { |name| "@#{name} = #{name}" }.join('; ')
      "def initialize(#{init_args}); #{init_assigns} end"
    end

    def definition_of_object_enhancements
      <<-RUBY
      def eql?(other); self.class == other.class && self == other end
      def hash; [self.class, self.class.portrayal.attributes(self)].hash end

      def ==(other)
        return super unless other.class.is_a?(Portrayal)

        self.class.portrayal.attributes(self) ==
          self.class.portrayal.attributes(other)
      end

      def freeze
        self.class.portrayal.attributes(self).values.each(&:freeze)
        super
      end

      def initialize_dup(source)
        self.class.portrayal.attributes(source).each do |key, value|
          instance_variable_set('@' + key.to_s, value.dup)
        end
        super
      end

      def initialize_clone(source)
        self.class.portrayal.attributes(source).each do |key, value|
          instance_variable_set('@' + key.to_s, value.clone)
        end
        super
      end
      RUBY
    end
  end
end
