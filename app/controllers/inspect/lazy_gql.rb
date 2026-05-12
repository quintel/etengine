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

    def respond_to_missing?(method_name)
      Gql::Gql.public_instance_methods.include?(method_name)
    end

    private

    def initialize_gql
      @scenario.gql(prepare: true)
    rescue Atlas::DocumentNotFoundError => e
      raise e unless e.message.match?(/could not find a dataset with the key/i)

      raise DatasetNotFoundError, "Dataset '#{@scenario.area_code}' not found for scenario #{@scenario.id}"
    end
  end
end
