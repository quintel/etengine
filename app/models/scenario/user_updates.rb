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

  # Inputs that run all the time and before the regular updates.
  # These should not be stored in the user_values, because they
  # will often change, by the researchers.
  # The inputs get the end_year as value.
  #
  def inputs_before
    unless @inputs_before
      @inputs_before = {}
      Input.before_inputs.each do |input|
        @inputs_before[input] = self.end_year
      end
    end
    @inputs_before
  end

  def inputs_present
    @inputs_present ||= input_values_for_graph(:present)
  end

  def inputs_future
    @inputs_future ||= input_values_for_graph(:future)
  end

  # This will process an {:input_id => :value} hash and update the inputs as needed
  #
  def update_inputs_for_api(params)
    params.each_pair do |input_id, value|
      if input = Input.get(input_id)
        if value == 'reset'
          delete_from_user_values(input.key)
        elsif typed_value = value.to_f
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
  # @tested 2010-12-06 seb
  #
  def update_input(input, value)
    key = input.key
    self.user_values.merge! key => value
    value
  end

  #
  # @untested 2010-12-22 seb
  #
  def delete_from_user_values(id)
    user_values.delete(id)
  end

  # These two methods are only used in the edit scenario form
  def user_values_as_yaml
    @yaml_error ? @invalid_yaml_values : user_values.to_hash.to_yaml
  end

  def user_values_as_yaml=(values)
    loaded = YAML.safe_load(values.to_s, [
      ActiveSupport::HashWithIndifferentAccess, Symbol
    ])

    self.user_values = (loaded || {}).with_indifferent_access
  rescue Psych::SyntaxError => ex
    @invalid_yaml_values = values.to_s
    @yaml_error = ex
  end

  def validate_no_yaml_error
    if @yaml_error
      errors.add(
        :user_values_as_yaml,
        "contains invalid YAML: #{@yaml_error.message}"
      )
    end
  end

  #######
  private
  #######

  # Internal: The inputs for which the user - or balancer - has specified a
  # value.
  #
  # Returns an array of inputs, in order of their execution priority.
  def inputs
    @inputs ||=
      combined_values.map { |key, _| Input.get(key) }.
      compact.sort_by { |input| [-input.priority, input.key] }
  end

  # Internal: A hash of inputs, and the values to be set on the named graph.
  #
  # name - The "name" of the graph for which you want values; :future or
  #        :present.
  #
  # Returns a hash.
  def input_values_for_graph(name)
    inputs.select { |input| input.public_send(:"updates_#{ name }?") }.
      each_with_object(Hash.new) do |input, hash|
        hash[input] = combined_values[input.key]
      end
  end

  # Internal: All of the inputs values to be set; includes the values
  # specified by the user, and any values from the balancer.
  #
  # Returns an hash.
  def combined_values
    @combined_values ||= balanced_values.merge(user_values)
  end

end  # Input
