module Opt
  class SliderGroupSetting
    include BaseSetting

    attr_reader :control, :step, :direction

    ##
    # @param [SliderGroupControl] slider_control
    # @param [:up, :down, :none] direction 
    # @param [Float] step_value force to use this step_value
    #
    def initialize(slider_control, direction, step_value = nil)
      @control = slider_control
      @direction = direction.to_sym
      @step_value = step_value
    end

    def step_value
      step_value_dynamic
      # step_value_fixed
    end

    ##
    # step value without adjustments.
    #
    # @deprecated
    #
    def step_value_fixed
      @step_value ||= control.step_value / control.group_sliders.length
    end

    ##
    # If step value is out of range, use 1/10 of the slider range. 
    # slider(min: -5, max: 7) => step_value = (7 - (-5)) / 10 = 1.2
    #
    # @return [Float] step value
    #
    def step_value_dynamic
      return @step_value if @step_value
      @step_value = control.step_value / control.group_sliders.length
      if out_of_range?(@step_value)
        @step_value = control.step_size_range / (10 * control.group_sliders.length)
      end
      @step_value
    end

    def inspect
      "<#{self.class.name} @direction=#{direction} @step_value=#{step_value} @value=#{value} @original_value=#{original_value} @control=#{control.input_element.name}>"
    end
  end

end