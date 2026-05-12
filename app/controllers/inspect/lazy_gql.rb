module Inspect
  # A wrapper around a scenario which exposes a Gql::Gql interface.
  #
  # Prevents calculating a scenario when it isn't needed.
  class LazyGql
    class DatasetNotFoundError < StandardError; end

    def initialize(scenario)
      @scenario = scenario
      @gql = nil
    end

    def method_missing(name, *args, &block)
      @gql ||= initialize_gql
      @gql.public_send(name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      Gql::Gql.public_instance_methods.include?(method_name) || super
    end

    private

    def initialize_gql
      @scenario.gql(prepare: true)
    rescue Atlas::DocumentNotFoundError, RuntimeError => e
      raise e unless dataset_not_found_error?(e)

      raise DatasetNotFoundError, "Dataset '#{@scenario.area_code}' not found for scenario #{@scenario.id}"
    end

    def dataset_not_found_error?(error)
      error.message.match?(/could not find a dataset with the key/i) ||
        error.message.match?(/no atlas data for/i) ||
        (error.message.include?('dataset') && error.message.include?(@scenario.area_code))
    end
  end
end
