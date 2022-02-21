module Inspect
  # A wrapper around a scenario which exposes a Gql::Gql interface.
  #
  # Prevents calculating a scenario when it isn't needed.
  class LazyGql
    def initialize(scenario)
      @scenario = scenario
      @gql = nil
    end

    def method_missing(name, *args, &block)
      @gql ||= @scenario.gql(prepare: true)
      @gql.public_send(name, *args, &block)
    end

    def respond_to_missing?(method_name)
      Gql::Gql.public_instance_methods.include?(method_name)
    end
  end
end
