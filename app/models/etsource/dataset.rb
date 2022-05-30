# ------ Examples -------------------------------------------------------------
#
#     et = Etsource::Dataset.new('nl')
#     et.import # => Qernel::Dataset for country 'nl'
#

module Etsource
  class Dataset
    attr_reader :country

    def initialize(country)
      # DEBT: @etsource is only used for the base_dir, can be solved better.
      @etsource = Etsource::Base.instance
      @country  = country
    end

    # Importing dataset and convert into the Qernel::Dataset format.
    # The yml file is a flat (no nested key => values) hash. We move it to a nested hash
    # and also have to convert the keys into a numeric using a hashing function (FNV 1a),
    # the additional nesting of the hash, and hashing ids as strings are mostly for
    # performance reasons.
    #
    def import
      ::Etsource::Dataset::Import.new(country).import
    end

    def self.insulation_costs(region_code, file)
      NastyCache.instance.fetch("insulation_cost.#{region_code}.#{file}") do
        Etsource::Dataset::InsulationCostMap.new(
          Atlas::Dataset.find(region_code).insulation_costs(file)
        )
      end
    end

    def self.weather_properties(region_code, variant_name)
      key = "weather_properties.#{region_code}.#{variant_name}"

      NastyCache.instance.fetch(key) do
        dataset = Atlas::Dataset.find(region_code)
        variant = dataset.curve_sets.get!('weather').variant!(variant_name)

        unless variant.curve?('weather_properties')
          raise "No weather_properties.csv found at #{variant.path}"
        end

        Atlas::CSVDocument.read(variant.curve_path('weather_properties'))
      end
    end

    def self.region_codes(refresh: false)
      NastyCache.instance.delete('region_codes') if refresh

      NastyCache.instance.fetch('region_codes') do
        Atlas::Dataset.all
          .select { |dataset| dataset.enabled[:etengine] }
          .map    { |dataset| dataset.key.to_s }
      end
    end
  end
end
