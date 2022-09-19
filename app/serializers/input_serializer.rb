class InputSerializer
  # Fetches the default value for an input from the dataset.
  class DefaultFromDataset
    def initialize(*); end

    def call(values)
      values[:default]
    end
  end

  # Fetches the default value for an input from the parent scenario, if set, otherwise from the
  # dataset.
  class DefaultFromParent
    def initialize(input, parent)
      @key = input.key
      @parent = parent
    end

    def call(values)
      @parent.user_values[@key] || @parent.balanced_values[@key] || values[:default]
    end
  end

  # Given an array of inputs, returns JSON for all of them.
  #
  # @param [Array<Input>] inputs
  #   The input for which we want JSON.
  # @param [Scenario] scenario
  #   The scenario whose values are being rendered.
  # @param [true, false] extras
  #   Do you want the extra attributes (key, unit, step) to be included in
  #   the output?
  def self.collection(inputs, scenario, extra_attributes: false, default_values_from: :parent)
    scenario = IndifferentScenario.from(scenario)

    inputs.each_with_object({}) do |input, data|
      data[input.key] = serializer_for(input, scenario, extra_attributes:, default_values_from:)
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
  def self.serializer_for(input, *args, **kwargs)
    klass = input.unit == 'enum' ? EnumInputSerializer : self
    klass.new(input, *args, **kwargs)
  end

  # Creates a new Input API serializer.
  #
  # @param [Input] input
  #   The input for which we want JSON.
  # @param [Scenario] scenario
  #   The scenario whose values are being rendered.
  # @param [boolean] extra_attributes
  #   Do you want the extra attributes (key, unit, step) to be included in
  #   the output?
  # @param [:parent, :original] default_values_from
  #   When a scenario inherits from another, the default values are set to be those from the parent
  #   scenario. Set this to `:original` to use the default values for the dataset instead.
  #
  def initialize(input, scenario, extra_attributes: false, default_values_from: :parent)
    @input               = input
    @scenario            = IndifferentScenario.from(scenario)
    @extra_attributes    = extra_attributes

    @default_values_from =
      if default_values_from == :parent && scenario.parent
        DefaultFromParent.new(input, scenario.parent)
      else
        DefaultFromDataset.new
      end
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
    json[:default] = @default_values_from.call(values)

    json[:unit] = @input.unit

    json[:user] = user_val if user_val.present?
    json[:cache_error] = values[:error] if values[:error]

    json[:disabled] = true if values[:disabled] || @scenario.inputs.disabled?(@input)
    json[:disabled_by] = @input.disabled_by if @input.disabled_by.present?

    json[:share_group] = @input.share_group if @input.share_group.present?

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

    delegate :inputs, :api_read_only?, to: :original

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
