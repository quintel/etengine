module Gql::UpdateInterface

class AttributeCommand < CommandBase
  MATCHER = /^(.*)_(decrease_total|decrease_rate|growth_rate|growth_total|value)$/

  def initialize(object, attr_name, command_value, type)
    super(object, attr_name, command_value)
    @type = type
  end

  def value
    self.send("value_#{@type}")
  end

  def validate
    if previous_value.nil?
      add_error :previous_value, "'#{@attr_name}' of #{@object} is nil"
    end
    #if @command_value.abs > 1.0
    #  add_error :command_value, "growth_per_year.abs is > 1.00"
    #end
  end

  def self.responsible?(key)
    attr_name, type = attr_name_and_type(key)
    type != nil
  end

  def self.create(graph, converter_proxy, key, value)
    attr_name, type = attr_name_and_type(key)
    new(converter_proxy, attr_name, value, type)
  end

private
  def self.attr_name_and_type(key)
    key.match(MATCHER).andand.captures
  end

  def value_decrease_rate
    years = Current.scenario.years
    growth_rate = 1.0 - @command_value
    previous_value * (growth_rate ** years)
  end

  def value_decrease_total
    growth = 1.0 - @command_value
    previous_value * growth
  end

  def value_growth_rate
    years = Current.scenario.years
    growth_rate = 1.0 + @command_value
    previous_value * (growth_rate ** years)
  end

  def value_growth_total
    growth = 1.0 + @command_value
    previous_value * growth
  end

  def value_value
    @command_value
  end
end

end
