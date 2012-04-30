module Gql::Grammar
  # ATTENTION: use :: namespace
  # Rubel::Base inherits from BasicObject. This means we don't have
  # access to the default namespace, so prepend classes and modules
  # with ::.
  class Sandbox < Rubel::Runtime::Sandbox

    attr_reader :scope

    def initialize(scope = nil)
      @scope = scope
    end

    def execute(query = nil)

      if query.is_a?(::String)
        query = sanitized_proc(query)
      end
      
      instance_exec(&query)
    rescue => e
      ::Rubel::ErrorReporter.new(e, query)
    end
    alias query execute

    include ::Gql::Grammar::Functions::Legacy
    include ::Gql::Grammar::Functions::Constants
    include ::Gql::Grammar::Functions::Traversal
    include ::Gql::Grammar::Functions::Aggregate
    include ::Gql::Grammar::Functions::Control
    include ::Gql::Grammar::Functions::Lookup
    include ::Gql::Grammar::Functions::Policy
    include ::Gql::Grammar::Functions::Update
    include ::Gql::Grammar::Functions::Helper
    include ::Gql::Grammar::Functions::Core
    
  end
end