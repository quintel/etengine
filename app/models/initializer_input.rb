class InitializerInput < BaseInput
  ATTRIBUTES = [*Atlas::InitializerInput.attribute_set.map(&:name), :key]

  attr_accessor *ATTRIBUTES

  def self.inputs
    Etsource::Loader.instance.initializer_inputs
  end
end
