module Gql::Grammar
  # Used for GQL console
  class Console
    include ::Rubel::Core
    
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
    

    # code completion is for the gql console.
    # it adds converter and gquery keys as methods,
    # so that PRY code completion picks it up. 
    #
    # The methods return the key as a symbol, which is
    # the same behaviour as with method_missing.
    #
    def enable_code_completion
      self.class.enable_code_completion(self)
    end

    def self.enable_code_completion(rubel_base)
      keys = [
        rubel_base.ALL().map(&:full_key),
        Gquery.all.map(&:key),
      ].flatten.
        map(&:to_sym) # really make sure keys are symbols

      keys.each do |converter_key|
        define_method converter_key do
          converter_key
        end
      end
    end
  end
end