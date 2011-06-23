module Opt
  ##
  # A SliderGroupControl is used for Share Groups, where a group of sliders
  # have to add up to a number (e.g. 100.0%). The SliderGroupControl actually
  # does not add up to a number (100%), instead it assumes that moving one 
  # slider up, another slider has to move down by the same amount.
  #
  # A SliderGroupControl has settings for every combination of other sliders
  # in that group.
  # E.g.
  # Sliders: A, B, C, Direction: up, down, none
  # [<A_up, B_down, C_none>, <A_up, B_none, C_down>, 
  # <A_down, B_up, C_none>, <A_down, B_none, C_up>, <A_none, B_none, C_none>]
  #
  # If one of the settings is out of the range of input (max, min_value)
  # that setting is rejected.
  #
  #
  class SliderGroupControl < SliderControl
    attr_accessor :direction, 
                  :current_step_value, 
                  :group_sliders,
                  :ranking

    attr_reader :input, :step_value, :min_value, :max_value

    def initialize(input, step_value)
      super
      self.group_sliders = []
    end

    ##
    #
    #
    def settings
      up = settings_in_direction(:up)
      dn = settings_in_direction(:down)
      [{self => default_setting}, up,dn].flatten
    end

    def other_sliders
      group_sliders - [self]
    end

    ##
    # Returns an Array of Hashes of all the combinations for that direction
    # e.g.
    # settings_in_direction([SliderGroupControl_1, SliderGroupControl_3, SliderGroupControl_3], :up)
    #
    # [
    #   {
    #     SliderGroupControl_1 => SliderGroupSetting_1_up, 
    #     SliderGroupControl_2 => SliderGroupSetting_2_down, 
    #     SliderGroupControl_3 => SliderGroupSetting_3_none
    #   },
    #   {
    #     SliderGroupControl_1 => SliderGroupSetting_1_up, 
    #     SliderGroupControl_2 => SliderGroupSetting_2_none, 
    #     SliderGroupControl_3 => SliderGroupSetting_3_down
    #   },
    #   { ... }
    # ]  
    #
    #
    # @param [Array<SliderGroupControl>] the other sliders in this group
    # @param [:up, :down, :none] direction of this slider
    # @return [Array<Hash(SliderControl => SliderSetting)>]
    #
    def settings_in_direction(direction)
      reverse_direction = BaseSetting.reverse_direction(direction)

      other_sliders.map do |reverse_slider| 
        # Every iteration one of the other_sliders acts as reverse slider
        setting = create_setting(direction)
        next if setting.out_of_range?

        # The "reverse slider" moves in the opposite direction
        #  by the step value of this slider #setting.step_value
        #  careful, take the step value of the setting.
        reverse_setting = reverse_slider.create_setting(reverse_direction, setting.step_value)
        next if reverse_setting.out_of_range?

        hsh = {self => setting, reverse_slider => reverse_setting}

        (other_sliders - [reverse_slider]).each do |s| 
          hsh[s] = s.create_setting(:none)
        end
        #raise "#{hsh.values.inspect}" if hsh.values.map(&:value).sum > 100.1
        hsh
      end.compact
    end

    ##
    # @return [Float] The range from min to max value
    #
    def step_size_range
      input.max_value - input.min_value
    end


    ##
    # @param [:up, :down, :none] direction of setting
    # @return [SliderGroupSetting]
    #
    def create_setting(direction, step_value = nil)
      SliderGroupSetting.new(self, direction, step_value)
    end

  end

end