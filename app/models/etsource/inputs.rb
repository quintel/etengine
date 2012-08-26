module Etsource
  class Inputs
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def export
      base_dir = "#{@etsource.base_dir}/inputs"

      FileUtils.mkdir_p(base_dir)
      Input.find_each do |input|
        attrs = input.attributes
        attrs.delete('created_at')
        attrs.delete('updated_at')
        File.open("#{base_dir}/#{input.key}.yml", 'w') do |f|
          f << YAML::dump(attrs)
        end
      end
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
