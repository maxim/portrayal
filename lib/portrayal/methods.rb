module Portrayal::Methods
  def eql?(other); self.class == other.class && self == other end
  def hash; [self.class, self.class.portrayal.attributes(self)].hash end
  def deconstruct; self.class.portrayal.attributes(self).values end

  def deconstruct_keys(keys)
    return self.class.portrayal.attributes(self) unless Array === keys
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
      instance_variable_set("@#{key}", value.dup)
    end
    super
  end

  def initialize_clone(source)
    self.class.portrayal.attributes(source).each do |key, value|
      instance_variable_set("@#{key}", value.clone)
    end
    super
  end
end
