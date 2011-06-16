module Opt
  ##
  # Handles individual sliders, they do not belong into a group.
  # A slider_control can have multiple settings, one for moving
  # *up* a slider by the defined step_value, one for *down*. The
  # *none* default_setting is the status quo of the previous step (the 
  # slider doesn't get moved).
  #
  #
  class SliderControl
    attr_accessor :current_step_value, 
                  :group_sliders, 
                  :step_value

    attr_reader :input_element, 
                :min_value, 
                :max_value


    ##
    # @param [Input] input_element
    # @param [Float] step_value
    #
    def initialize(input_element, step_value)
      @input_element = input_element
      @min_value = input_element.min_value
      @max_value = input_element.max_value
      @step_value = step_value.to_f
      @current_step_value = @input_element.user_value
    end

    ##
    # @return [SliderSetting] Default setting (:none)
    #
    def default_setting
      create_setting(:none)
    end

    ##
    # All possible slider_settings for this slider
    #
    # @return [Array<SliderSetting>]
    #
    def settings
      [
        {self => default_setting},
        {self => create_setting(:up)},
        {self => create_setting(:down)}
      ]
    end

    ##
    # @param [:up, :down, :none] direction of setting
    # @return [SliderSetting]
    #
    def create_setting(direction)
      SliderSetting.new(self, direction)
    end

    ##
    # Updates the GQL with the given SliderSetting.
    #
    # @param [SliderSetting] slider_setting
    #
    def update(slider_setting)
      value = slider_setting.value
      input_element.update_current(value)
    end

    def to_json(options = {})
      ActiveSupport::JSON.encode({:slider_control => {
          :id => self.input_element.id, 
          :current_value => self.input_element.user_value}
      }) 
    end

    def inspect
      "<#{self.class.name} @control=#{input_element.name}>"
    end
  end

end