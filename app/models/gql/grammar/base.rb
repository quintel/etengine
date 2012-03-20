module Gql::Grammar
  # ATTENTION: use :: namespace
  # Rubel::Base inherits from BasicObject. This means we don't have
  # access to the default namespace, so prepend classes and modules
  # with ::.
  class Base < Rubel::Base
    include ::Gql::Grammar::Functions::Legacy
    # now override with freshened up gql functions
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