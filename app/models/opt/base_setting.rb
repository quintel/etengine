module Opt
  module BaseSetting

    ##
    # @param [Float] slider value
    #
    def value
      unless @value
        value = calculate_value(step_value)
        @value = value_within_range(value)
      end
      @value
    end

    ##
    # Is setting higher then max value or lower then min value?
    #
    # @param [Float] step_size uses settings step_value per default
    # @return [true,false]
    #
    def out_of_range?(step_size = step_value)
      value = calculate_value(step_size)
      #(control.min_value..control.max_value).include?(value)
      if value > control.max_value
        true
      elsif value < control.min_value
        true
      else
        false
      end
    end

    ##
    # Gets the new value for this setting depending on its direction
    #
    # @param [Float] step_value new value based on this step_value
    # @return [Float]
    #
    def calculate_value(step_value)
      case direction
      when :up
        original_value + step_value
      when :down
        original_value - step_value
      else
        original_value
      end
    end

    ##
    # @return [Float] Value from previous step.
    #
    def original_value
      @original_value ||= control.current_step_value
    end

    ##
    # Returns the value inside the min,max boundaries.
    # Returns min,max if value is out of range.
    #
    # @param [Float]
    # @return [Float]
    #
    def value_within_range(value)
      if value > control.max_value
        control.max_value
      elsif value < control.min_value
        control.min_value
      else
        value
      end
    end

    ##
    # @return [:up, :down, :none] the reverse direction
    #
    def reverse_direction
      BaseSetting.reverse_direction(direction)
    end

    ##
    # Is the setting doing anything? going up or down?
    #
    # @return [true, false] false if :none
    #
    def has_action?
      direction != :none
    end

    ##
    # @param [:up, :down, :none]
    # @return [:up, :down, :none] the reverse direction
    #
    def self.reverse_direction(direction)
      direction = direction.to_sym
      if direction == :up
        :down
      elsif direction == :down
        :up
      else
        :none
      end
    end
  end
end
