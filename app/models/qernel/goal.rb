# This is a very dumb object. An array of them is store in Gql::Gql#goals
#
module Qernel
  class Goal
    attr_accessor :key, :user_value

    def initialize(key)
      self.key = key.to_sym
    end
     
    def is_set?
      !user_value.nil?
    end
    
    # GQL updates assign values using the array syntax
    # See gql_expression.rb
    # 
    def []=(attr_name, value)
      writer_method = "#{attr_name}="
      send(writer_method, value) if respond_to?(writer_method)
    end
  end
end