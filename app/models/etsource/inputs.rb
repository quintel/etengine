module Etsource
  class Inputs
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def import
      base_dir = "#{@etsource.export_dir}/inputs"

      Dir.glob("#{base_dir}/**/*.yml").map do |f|
        attributes = YAML.load_file(f)
        attributes[:key] = f.split('/').last.split('.').first.strip
        attributes[:lookup_id] ||= attributes.delete('id')
        Input.new(attributes)
      end
    end

  end
end
