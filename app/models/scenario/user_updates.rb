# Handles user input.
#
# {#user_values} is a hash of Input#id => user_value
#
# user_values alone cannot be used by the gql, we need to translate them
# into a update_statements hash it is split into the subhashes :carriers,
# :converters, :area. To define what kind of objects need to be updated.
#
# Based on Input#updateable_period a update_statement is added to either 
# update_statements, update_statements_present or both. 
#
# {#update_statements} updates for the future graph.
# {#update_statements_present} updates for the present graph.
#
#
module Scenario::UserUpdates
  extend ActiveSupport::Concern

  def included(klass)
    klass.include(InstanceMethods)
  end

  module InstanceMethods

    def update_statements=(stmts)
      @update_statements = stmts
    end

    def update_statements
      @update_statements ||= {}
    end

    def update_statements_present=(stmts)
      @update_statements_present = stmts
    end

    def update_statements_present
      @update_statements_present ||= {}
    end

    # TODO fix
    # @untested 2011-01-24 seb
    #
    def update_inputs_for_api(params)
      input_ids = params.keys
      input_ids.each do |key|
        if input = Input.get_cached(key)
          if params[key] == 'reset'
            delete_from_user_values(input.id)
          elsif value = params[key].to_f
            update_input(input, value)
          end
        else
          Rails.logger.warn("Scenario#update_inputs_for_api: Trying to update an input that doesn't exist. id: #{key}")
        end
      end
    end

    # This method sends the key values to the gql using the input element attr. 
    # Also it fills an array with input elements which must be updated after the calculation
    #
    # @param input <Object> the updated input element
    # @param value <Float> the posted value
    #
    # @tested 2010-12-06 seb
    # 
    def update_input(input, value)
      store_user_value(input, value)
      add_update_statements(input.update_statement(value), input.updateable_period)
    end

    # add_update_statements does not persist the slider value.
    # ie. if you update a scenario with add_update_statements the changes
    # are made (and persist), but it does not affect a slider in the UI.
    #
    # Use this method only if there are some sort of "hidden" updates.
    #
    # @param [Hash] update_statement_hash
    #   {'converters' => {'converter_key' => {'update' => value}}}
    #
    # @tested 2010-12-06 seb
    #
    def add_update_statements(update_statement_hash, updateable_period = :future)
      if Current.gql_calculated?
        raise "Update statements are ignored after the GQL has finished calculating. \nStatement: \n#{update_statement_hash.inspect}" 
      end
      # This has to be self.update_statements otherwise it doesn't work
      # use deep_merge!
      case updateable_period.to_sym
      when :future  then self.update_statements.deep_merge!(update_statement_hash)
      when :present then self.update_statements_present.deep_merge!(update_statement_hash)
      when :both
        self.update_statements.deep_merge!(update_statement_hash)
        self.update_statements_present.deep_merge!(update_statement_hash)
      else
        Rails.logger.warn("***** No updateable_period")
      end
    end

    # Stores the user value in the session.
    #
    # @param [Input] input
    # @param [Flaot] value
    # @return [Float] the value
    #
    # @tested 2010-11-30 seb
    #
    def store_user_value(input, value)
      key = input.id
      self.user_values.merge! key => value
      touch(:present_updated_at) if input.updates_present?
      value
    end

    # @tested 2010-11-30 seb
    #
    def user_value_for(input)
      user_values[input.id]
    end

    # TODO fix this, it's weird
    #
    # DEBT: This has had it's fair share of refactorings behind. 
    #       Make the serialization of user_values more straightforward
    #
    # Holds all values chosen by the user for a given slider. 
    # Hash {input.id => Float}, e.g.
    # {3=>-1.1, 4=>-1.1, 5=>-1.1, 6=>-1.1, 203=>1.1, 204=>0.0}
    #
    # @tested 2010-11-30 seb
    #
    def user_values
      unless @user_values_hash
        self[:user_values] ||= {}.to_yaml
        @user_values_hash = YAML::load(self[:user_values])
      end
      @user_values_hash
    end

    # Sets the user_values.
    #    
    # @untested 2010-12-22 jape
    #    
    def user_values=(values)
      values ||= {}
      if values.is_a?(Hash)
        @user_values_hash = values
      elsif values.is_a?(String)
        @user_values_hash = YAML::load(values)
      else 
        raise ArgumentError.new("You must set either a hash or a string: " + values.inspect)
      end
    end


    # Deletes a uesr_value completely
    #
    # @untested 2010-12-22 seb
    #
    def delete_from_user_values(id)
      self.user_values.delete(id)
    end

    # Builds update_statements from user_values that are readable by the GQl. 
    #
    # @param [Boolean] load_as_municipality
    #
    # @untested 2010-12-06 seb
    #
    def build_update_statements
      user_values.each_pair do |id, value|
        build_update_statements_for_element(id, value)
      end
    end

    # Called from build_update_statements
    #
    # @param [Boolean] load_as_municipality
    # @param [Integer] id Input#id
    # @param [Float] value user value
    #
    # @tested 2010-12-06 seb
    #
    def build_update_statements_for_element(id, value)
      if input = Input.get_cached(id)
        update_input(input, value)
      else
        Rails.logger.warn("WARNING: Scenario loaded, but Input nr.#{id} was not found")    
      end
    end
  end

end