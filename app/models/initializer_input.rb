class InitializerInput
  include Input::Common

  ATTRIBUTES = [*Atlas::InitializerInput.attribute_set.map(&:name), :key]

  attr_accessor *ATTRIBUTES

  def self.get(key)
    super(key.to_s)
  end

  def self.fetch(key)
    super(key.to_s)
  end

  def self.inputs
    Etsource::Loader.instance.initializer_inputs
  end
end
