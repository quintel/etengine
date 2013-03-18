module Etsource

  class Inputs
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def import
      ETSource::Input.all.map do |input|
        attributes = input.to_hash
        attributes[:lookup_id] ||= attributes.delete(:id)
        attributes[:key] = input.key
        Input.new(attributes)
      end
    end

  end # class inputs

end # module Etsource
