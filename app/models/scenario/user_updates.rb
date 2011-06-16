##
# Update statements. 
# Handling of user input
#
class Scenario < ActiveRecord::Base



  attr_writer :update_statements

  def update_statements
    @update_statements ||= {}
  end


  ##
  # TODO fix
  # @untested 2011-01-24 seb
  #
  def update_input_elements_for_api(params)
    input_element_ids = params.keys
    input_element_ids.each do |key|
      input_element = Input.where(['id = ? or `key` = ?', key,key]).first

      if params[key] == 'reset'
        delete_from_user_values(input_element.id)
      elsif value = params[key].to_f
        # To prevent javascript hacking for disabled sliders we do an extra check. This is needed for the transition price
        unless input_element.disabled
          update_input_element(input_element, value)
        end
      end
    end
    add_update_statements(lce.update_statements)
  end

  ##
  # This method sends the key values to the gql using the input element attr. 
  # Also it fills an array with input elements which must be updated after the calculation
  #
  # @param input_element <Object> the updated input element
  # @param value <Float> the posted value
  #
  # @tested 2010-12-06 seb
  # 
  def update_input_element(input_element, value)
    store_user_value(input_element, value)
    add_update_statements(input_element.update_statement(value))
  end

  ##
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
  def add_update_statements(update_statement_hash)
    if Current.gql_calculated?
      raise "Update statements are ignored after the GQL has finished calculating. \nStatement: \n#{update_statement_hash.inspect}" 
    end
    # This has to be self.update_statements otherwise it doesn't work
    self.update_statements = self.update_statements.deep_merge(update_statement_hash)
  end

  ##
  # Stores the user value in the session.
  #
  # @param [Input] input_element
  # @param [Flaot] value
  # @return [Float] the value
  #
  # @tested 2010-11-30 seb
  #
  def store_user_value(input_element, value)
    key = input_element.id
    self.user_values = self.user_values.merge key => value 
    value
  end


  ##
  # @tested 2010-11-30 seb
  #
  def user_value_for(input_element)
    user_values[input_element.id]
  end

  ##
  # TODO fix this, it's weird
  #
  # Holds all values chosen by the user for a given slider. 
  # Hash {input_element.id => Float}, e.g.
  # {3=>-1.1, 4=>-1.1, 5=>-1.1, 6=>-1.1, 203=>1.1, 204=>0.0}
  #
  # @tested 2010-11-30 seb
  #
  def user_values
    self[:user_values] ||= {}.to_yaml
    YAML::load(self[:user_values])
  end

  ##
  # Sets the user_values.
  #    
  # @untested 2010-12-22 jape
  #    
  def user_values=(values)
    values ||= {}
    self[:user_values] = case values
      when Hash then values.to_yaml
      when String then values
      else raise ArgumentError.new("You must set either a hash or a string: " + values.inspect)
    end
  end


  ##
  # Deletes a uesr_value completely
  #
  # @untested 2010-12-22 seb
  #
  def delete_from_user_values(id)
    values = user_values
    values.delete(id)
    self.user_values = values
  end

  ##
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

  ##
  # Called from build_update_statements
  #
  # @param [Boolean] load_as_municipality
  # @param [Integer] id Input#id
  # @param [Float] value user value
  #
  # @tested 2010-12-06 seb
  #
  def build_update_statements_for_element(id, value)

    input_element = Input.find(id)
    update_input_element(input_element, value)

  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("WARNING: Scenario loaded, but Input nr.#{id} was not found")    
  end

end