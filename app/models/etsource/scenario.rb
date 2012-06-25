module Etsource
  class Scenario
    def initialize
      @etsource = Etsource::Base.instance
    end

    def presets
      base_dir = "#{@etsource.export_dir}/presets"

      presets = []
      Dir.glob("#{base_dir}/*.yml").each do |f|
        attributes = YAML::load_file(f).with_indifferent_access
        presets << Preset.new(attributes)
      end
      presets
    end
    
  end
end
