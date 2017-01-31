module Etsource
  class Inputs
    def initialize(etsource = Etsource::Base.instance, atlas_class, etengine_class)
      @etsource       = etsource
      @atlas_class    = atlas_class
      @etengine_class = etengine_class
    end

    def import
      @atlas_class.all.map do |input|
        attributes             = input.to_hash
        attributes[:key]       = input.key.to_s
        attributes[:file_path] = input.path

        @etengine_class.new(attributes)
      end
    end
  end # class inputs
end # module Etsource
