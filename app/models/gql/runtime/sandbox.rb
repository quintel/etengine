module Gql::Runtime
  # ATTENTION: use :: namespace
  # Rubel::Base inherits from BasicObject. This means we don't have
  # access to the default namespace, so prepend classes and modules
  # with ::.
  class Sandbox < Rubel::Runtime::Sandbox

    attr_reader :scope

    def initialize(scope = nil)
      @scope = scope
    end

    include ::Gql::Runtime::Functions::Legacy
    include ::Gql::Runtime::Functions::Constants
    include ::Gql::Runtime::Functions::Traversal
    include ::Gql::Runtime::Functions::Aggregate
    include ::Gql::Runtime::Functions::Control
    include ::Gql::Runtime::Functions::Lookup
    include ::Gql::Runtime::Functions::Policy
    include ::Gql::Runtime::Functions::Update
    include ::Gql::Runtime::Functions::Helper
    include ::Gql::Runtime::Functions::Core
    
  end
end