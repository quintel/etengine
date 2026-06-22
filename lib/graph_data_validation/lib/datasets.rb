# frozen_string_literal: true
require 'yaml'

module GraphDataValidation
  class Datasets
    include Enumerable

    def initialize(*area_codes, env: :dev)
      # Connect with etsource in development. This should also be extracted later
      if env == :dev
        Settings.etsource_lazy_load_dataset = true
        Atlas.data_dir = Etsource::Base.clean_path(File.expand_path("../etsource"))
      end

      # Silently reject unexisting areas
      @area_codes = area_codes.reject { |area| !Atlas::Dataset.exists?(area) }
    end

    def each(&block)
      @area_codes.each do |code|
        gql = gql_for(code)
        yield gql if gql.present?
      end
    end

    def self.from_collection(key)
      # We create a new config here now for simplicity,
      # should be extracted to something more proper at one point
      self.new(*Config.new.dataset_collection(key))
    end

    private

    def gql_for(area_code)
      # TODO: Can we get gql without scenario?
      puts "Running #{area_code}..."
      Scenario.new(area_code: area_code).gql
    rescue RuntimeError => e
      puts "#{area_code} causes error: #{e.message}, skipping..."
    end
  end

  class Config
    CONFIG_PATH = File.expand_path('../config.yml', __dir__)

    def dataset_collection(key)
      return unless dataset_collection?(key)

      raw_config['dataset_collections'][key]
    end

    def dataset_collection?(key)
      raw_config['dataset_collections']&.key?(key)
    end

    private

    def raw_config
      @raw_config ||= YAML.load_file(CONFIG_PATH).with_indifferent_access
    end
  end
end

