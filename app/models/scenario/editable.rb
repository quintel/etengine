# frozen_string_literal: true

# Editable is a wrapper around scenario which exposes some of the internal "store" values as strings
# which can be edited by a user through the inspect interface. User and balanced values are exposed
# as a YAML string, while metadata is displayed as pretty- printed JSON.
#
# This class also handles conversion back from strings to the correct data types used by Scenario,
# as well as handling parse errors.
class Scenario::Editable < SimpleDelegator
  def initialize(scenario)
    super(scenario)

    @scenario = scenario
    @raw = {}
  end

  def update!(params)
    self.metadata = params[:metadata]
    self.user_values = params[:user_values]
    self.balanced_values = params[:balanced_values]
    params[:active_couplings].to_s.split.each { |coupling| self.activate_coupling(coupling.to_sym) }
    @scenario.attributes = params.except(
      :metadata,
      :user_values,
      :balanced_values,
      :active_couplings
    )

    raise ActiveRecord::RecordInvalid if @scenario.errors.any?

    @scenario.save!
  end

  # Public: Returns self. Required to show values in the form.
  def to_model
    self
  end

  # Public: The user values as YAML. If the values have been set by the user through a form, this
  # returns the value they gave.
  def user_values
    value_of(:user_values, method(:nice_yaml))
  end

  # Public: Sets the user values. Expects a string containing YAML.
  def user_values=(string)
    set_yaml(:user_values, string)
  end

  # Public: The balanced values as YAML. If the values have been set by the user through a form,
  # this returns the value they gave.
  def balanced_values
    value_of(:balanced_values, method(:nice_yaml))
  end

  # Public: Sets the balanced values. Expects a string containing YAML.
  def balanced_values=(string)
    set_yaml(:balanced_values, string)
  end

  # Public: The metadata values as JSON. If the values have been set by the user through a form,
  # this returns the value they gave.
  def metadata
    value_of(:metadata, JSON.method(:pretty_generate), '{}')
  end

  # Public: Sets the metadata. Expects a string containing JSON.
  def metadata=(string)
    return if string.nil?

    @raw[:metadata] = string.presence || '{}'
    @scenario.metadata = JSON.parse(@raw[:metadata])
  rescue JSON::ParserError => e
    @scenario.errors.add(:metadata, "is not valid JSON: #{e.message}")
  end

  private

  def value_of(key, dump, fallback = '')
    return @raw[key].to_s.rstrip if @raw[key]

    value = @scenario.public_send(key)
    value.blank? ? fallback : dump.call(value.to_h).rstrip
  end

  def set_yaml(key, value)
    return if value.nil?

    @raw[key.to_sym] = value
    @scenario.public_send("#{key}=", YAML.safe_load(value))
  rescue Psych::SyntaxError => e
    @scenario.errors.add(key, "is not valid YAML: #{e.message}")
  end

  # Internal: Converts a hash to YAML, removing the "---" document start indicator.
  def nice_yaml(string)
    YAML.dump(string).gsub(/\A---\n/, '')
  end
end
