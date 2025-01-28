require 'portrayal/default'

class Portrayal::Schema
  attr_reader :schema, :module
  NULL = Object.new.freeze

  def initialize;       @schema = {}; @module = Module.new                end
  def keywords;         @schema.keys                                      end
  def attributes(obj);  Hash[keywords.map { |k| [k, obj.send(k)] }]       end
  def camelize(string); string.to_s.gsub(/(?:^|_+)([^_])/) { $1.upcase }  end

  def initialize_dup(src)
    @schema = src.schema.transform_values(&:dup)
    @module = src.module.dup
    super
  end

  def add_keyword(name, default)
    name = name.to_sym
    @schema.delete(name) # Forcing keyword to be added at the end of the hash.
    @schema[name] = default.equal?(NULL) ? nil : Portrayal::Default.new(default)
    @module.module_eval(render_module_code)
  end

  def render_module_code
    args, inits, syms, hash, eqls, dups, clones, setters, freezes, aliases =
      +'', +'', +'', +'', +'', +'', +'', +'', +'', +'' # + keeps string unfrozen

    @schema.each do |k, default|
      args  << "#{k}:#{default && " self.class.portrayal.schema[:#{k}]"}, "
      inits << "@#{k} = #{k}.is_a?(::Portrayal::Default) ? #{k}.(self) : #{k}; "
      syms  << ":#{k}, "
      hash  << "#{k}: @#{k}, "
      eqls  << "@#{k} == other.instance_variable_get('@#{k}') && "
      dups  << "@#{k} = src.instance_variable_get('@#{k}').dup; "
      clones  << "@#{k} = src.instance_variable_get('@#{k}').clone; "
      setters << ":#{k}=, "
      freezes << "@#{k}.freeze; "
      aliases << "alias #{k} #{k}; alias #{k}= #{k}=; "
    end

    args.chomp!(', ')    # key1:, key2: self.class.portrayal.schema[:key2]
    inits.chomp!('; ')   # Assignments in initialize
    syms.chomp!(', ')    # :key1, :key2
    hash.chomp!(', ')    # key1: @key1, key2: @key2
    eqls.chomp!(' && ')  # @key1 == other.instance_variable_get('@key1') &&
    dups.chomp!('; ')    # @key1 = src.instance_variable_get('@key1').dup;
    clones.chomp!('; ')  # @key1 = src.instance_variable_get('@key1').clone;
    setters.chomp!(', ') # :key1=, :key2=
    freezes.chomp!('; ') # @key1.freeze; @key2.freeze
    aliases.chomp!('; ') # alias key1 key1; alias key1= key1=

    # Aliases at the bottom help prevent method redefinition warnings.
    # See https://bugs.ruby-lang.org/issues/17055 for details.
    <<-RUBY
attr_accessor #{syms}
protected #{setters}
def initialize(#{args}); #{inits} end
def hash; [self.class, {#{hash}}].hash end
def ==(other); self.class == other.class && #{eqls} end
alias eql? ==
def freeze; #{freezes}; super end
def initialize_dup(src); #{dups}; super end
def initialize_clone(src); #{clones}; super end
def deconstruct
  public_syms = [#{syms}].select { |s| self.class.public_method_defined?(s) }
  public_syms.map { |s| public_send(s) }
end
def deconstruct_keys(keys)
  filtered_keys = [#{syms}].select {|s| self.class.public_method_defined?(s) }
  filtered_keys &= keys if Array === keys
  Hash[filtered_keys.map { |k| [k, public_send(k)] }]
end
alias initialize initialize
alias hash hash
alias == ==
alias eql? eql?
alias freeze freeze
alias initialize_dup initialize_dup
alias initialize_clone initialize_clone
alias deconstruct deconstruct
alias deconstruct_keys deconstruct_keys
#{aliases}
    RUBY
  end
end
