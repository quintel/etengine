module Opt
  class SliderSetting
    include BaseSetting

    attr_reader :control, :step, :direction

    ##
    #
    #
    def initialize(slider_control, direction)
      @control = slider_control
      @direction = direction.to_sym
    end

    def step_value
      control.step_value
    end

    def inspect
      "<#{self.class.name} @direction=#{direction} @value=#{value} @control=#{control.input_element.name}>"
    end

  end

end