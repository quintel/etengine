class InputSerializer
  # Given an array of inputs, returns JSON for all of them.
  #
  # @param [Array<Input>] inputs
  #   The input for which we want JSON.
  # @param [Scenario] scenario
  #   The scenario whose values are being rendered.
  # @param [true, false] extras
  #   Do you want the extra attributes (key, unit, step) to be included in
  #   the output?
  def self.collection(inputs, scenario, extras = false)
    scenario = IndifferentScenario.from(scenario)

    inputs.each_with_object({}) do |input, data|
      data[input.key] = serializer_for(input, scenario, extras)
    end
  end

  # Public: Creates an appropriate serializer for the given input.
  #
  # @param [Input] input
  #   The input for which we want JSON.
  #
  # @see InputSerializer#initialize
  #
  # @return [InputSerializer]
  #   Returns the input serializer (or subclass) instance.
  def self.serializer_for(input, *args)
    klass = input.unit == 'enum' ? EnumInputSerializer : self
    klass.new(input, *args)
  end

  # Creates a new Input API serializer.
  #
  # @param [Input] input
  #   The input for which we want JSON.
  # @param [Scenario] scenario
  #   The scenario whose values are being rendered.
  # @param [true, false] extra_attributes
  #   Do you want the extra attributes (key, unit, step) to be included in
  #   the output?
  #
  def initialize(input, scenario, extra_attributes = false)
    @input            = input
    @scenario         = IndifferentScenario.from(scenario)
    @extra_attributes = extra_attributes
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # @return [Hash{Symbol=>Object}]
  #   The Hash containing the input attributes.
  #
  def as_json(*)
    json = {}
    values = Input.cache(@scenario.original).read(@scenario.original, @input)

    user_values = @scenario.user_values
    balanced_values = @scenario.balanced_values

    user_val = user_values[@input.key] || balanced_values[@input.key]

    json[:min] = values[:min]
    json[:max] = values[:max]
    json[:default] = values[:default]

    json[:unit] = @input.unit

    json[:user] = user_val if user_val.present?
    json[:cache_error] = values[:error] if values[:error]

    # An input is disabled if the cache says so, or if a mutually-exclusive input is present.
    json[:disabled] = true if values[:disabled] || @scenario.inputs.disabled_by_exclusivity?(@input)
    json[:disables_inputs] = @input.disables if @input.disables.present?

    json[:share_group] = @input.share_group if @input.share_group.present?

    if (parent = @scenario.parent)
      json[:default] =
        parent.user_values[@input.key] ||
        parent.balanced_values[@input.key] ||
        json[:default]
    end

    if @extra_attributes
      json[:step] = values[:step] || @input.step_value
      json[:code] = @input.key
    end

    json[:label] = { value: values[:label], suffix: @input.label } if values[:label].present?

    json
  end

  # A simple wrapper around Scenario which converts user and balanced values
  # to an indifferent-access hash. Prevents creating new copies of these
  # hashes for each and every input being presented.
  class IndifferentScenario
    attr_reader :original

    delegate :inputs, to: :original

    def self.from(scenario)
      scenario.is_a?(self) ? scenario : new(scenario)
    end

    def initialize(original)
      @original = original
    end

    def user_values
      @user ||= ActiveSupport::HashWithIndifferentAccess.new(
        @original.user_values
      )
    end

    def balanced_values
      @balanced ||= ActiveSupport::HashWithIndifferentAccess.new(
        @original.balanced_values
      )
    end

    def parent
      @parent ||=
        @original.parent && IndifferentScenario.from(@original.parent)
    end
  end
end
