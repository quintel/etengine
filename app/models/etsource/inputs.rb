module Etsource
  class Inputs
    INPUTS = {
      Atlas::Input => Input,
      Atlas::InitializerInput => InitializerInput
    }

    def initialize(etsource = Etsource::Base.instance, input_class = Atlas::Input)
      @etsource    = etsource
      @input_class = input_class
    end

    def import
      @input_class.all.map do |input|
        attributes             = input.to_hash
        attributes[:key]       = input.key.to_s
        attributes[:file_path] = input.path

        INPUTS.fetch(@input_class).new(attributes)
      end
    end
  end # class inputs
end # module Etsource
