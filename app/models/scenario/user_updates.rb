# Handles user input.
#
# {#user_values} is a hash of Input#id => user_value
#
# user_values alone cannot be used by the gql, we need to translate them
# into a update_statements hash it is split into the subhashes :carriers,
# :nodes, :area. To define what kind of objects need to be updated.
#
# Based on Input#update_period a update_statement is added to either
# update_statements, update_statements_present or both.
#
#
module Scenario::UserUpdates
  extend ActiveSupport::Concern

  # Public: Returns a helper object for retrieving the user-specified values for the scenario.
  def inputs
    @inputs ||= Scenario::Inputs.new(self)
  end

  # This will process an {:input_id => :value} hash and update the inputs as needed
  #
  def update_inputs_for_api(params)
    params.each_pair do |input_id, value|
      if (input = Input.get(input_id))
        if value == 'reset'
          delete_from_user_values(input.key)
        elsif (typed_value = value.to_f)
          update_input(input, typed_value)
        end
      else
        Rails.logger.warn("Scenario#update_inputs_for_api: Trying to update an input that doesn't exist. id: #{input_id}")
      end
    end
  end

  # This method sends the key values to the gql using the input element attr.
  # Also it fills an array with input elements which must be updated after the calculation
  #
  # @param input <Object> the updated input element
  # @param value <Float> the posted value
  #
  def update_input(input, value)
    if value.nil?
      user_values.delete(input.key)
    else
      user_values[input.key] = value
    end

    value
  end

  def update_input_clamped(input, value)
    input = Input.get(input) unless input.is_a?(Input)

    update_input(input, input.clamp(self, value))
  end

  #
  # @untested 2010-12-22 seb
  #
  def delete_from_user_values(id)
    user_values.delete(id)
  end
end
