require 'portrayal/default'
require 'portrayal/methods'

class Portrayal::Schema
  attr_reader :schema
  NULL = Object.new.freeze

  def initialize;         @schema = {}                                      end
  def keywords;           @schema.keys                                      end
  def [](name);           @schema[name]                                     end
  def empty?;             @schema.empty?                                    end
  def attributes(object); Hash[keywords.map { |k| [k, object.send(k)] }]    end
  def camelize(string);   string.to_s.gsub(/(?:^|_+)([^_])/) { $1.upcase }  end
  def initialize_dup(o);  @schema = o.schema.transform_values(&:dup); super end

  def add_keyword(name, default)
    name = name.to_sym
    @schema.delete(name) # Forcing keyword to be added at the end of the hash.
    @schema[name] = default.equal?(NULL) ? nil : Portrayal::Default.new(default)
  end

  def render_initialize
    args, assigns = '', ''

    @schema.each do |key, default|
      args    << "#{key}:#{default && " self.class.portrayal[:#{key}]"}, "
      assigns << "@#{key} = #{key}.is_a?(::Portrayal::Default) ? " \
                 "#{key}.get(self) : #{key}; "
    end

    args.chomp!(', ')
    assigns.chomp!('; ')
    "def initialize(#{args}); #{assigns} end"
  end
end
