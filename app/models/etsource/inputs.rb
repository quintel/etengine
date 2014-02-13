module Etsource

  class Inputs
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def import
      Atlas::Input.all.map do |input|
        attributes             = input.to_hash
        attributes[:key]       = input.key.to_s
        attributes[:file_path] = input.path

        Input.new(attributes)
      end
    end

  end # class inputs

end # module Etsource
