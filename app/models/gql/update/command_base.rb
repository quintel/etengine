module Gql::Update

class CommandBase
  attr_reader :object

  def initialize(object, attr_name, command_value)
    @object = object
    @attr_name = attr_name
    @command_value = command_value.to_f
  end

  def execute
    unless valid?
      Rails.logger.warn(@errors.values.join('\n'))
      return nil
    end
    object[@attr_name] = value
  end

  def value
    raise "value not implemented"
    # implement
  end

private
  def previous_value
    # introducted for backwards support for old blackboxes
    if object.respond_to?(@attr_name)
      object.send(@attr_name) 
    else
      nil
    end
  end

  def valid?
    return true unless respond_to?(:validate)
    validate
    @errors.nil? or @errors.empty?
  end

  def add_error(key, msg)
    @errors ||= {}
    @errors[key] = msg
  end


end

end
