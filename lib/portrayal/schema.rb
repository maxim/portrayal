require 'portrayal/default'

module Portrayal
  class Schema
    attr_reader :schema

    DEFINITION_OF_OBJECT_ENHANCEMENTS = <<~RUBY.freeze
      def eql?(other); self.class == other.class && self == other end
      def hash; [self.class, self.class.portrayal.attributes(self)].hash end
      def deconstruct; self.class.portrayal.attributes(self).values end

      def deconstruct_keys(keys)
        keys ||= self.class.portrayal.keywords
        keys &= self.class.portrayal.keywords
        Hash[keys.map { |k| [k, send(k)] }]
      end

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
          instance_variable_set("@\#{key}", value.dup)
        end
        super
      end

      def initialize_clone(source)
        self.class.portrayal.attributes(source).each do |key, value|
          instance_variable_set("@\#{key}", value.clone)
        end
        super
      end
    RUBY

    def initialize; @schema = {}  end
    def keywords;   @schema.keys  end
    def [](name);   @schema[name] end

    def attributes(object)
      Hash[object.class.portrayal.keywords.map { |k| [k, object.send(k)] }]
    end

    def camelize(string); string.to_s.gsub(/(?:^|_+)([^_])/) { $1.upcase } end

    def add_keyword(name, default)
      name = name.to_sym
      @schema.delete(name) # Forcing keyword to be added at the end of the hash.
      @schema[name] = default.equal?(NULL) ? nil : Default.new(default)
    end

    def initialize_dup(other)
      super; @schema = other.schema.transform_values(&:dup)
    end

    def definition_of_initialize
      init_args = @schema.map { |name, default|
        "#{name}:#{default && " self.class.portrayal[:#{name}]"}"
      }.join(', ')

      init_assigns = @schema.keys.map { |name|
        "@#{name} = #{name}.is_a?(::Portrayal::Default) ? " \
          "(#{name}.call? ? instance_exec(&#{name}.value) : #{name}.value) : " \
          "#{name}"
      }.join('; ')

      "def initialize(#{init_args}); #{init_assigns} end"
    end
  end
end
