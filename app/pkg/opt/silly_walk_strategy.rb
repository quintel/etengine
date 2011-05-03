module Opt
  #
  # Original optimization strategy.
  #
  # This is included into step.rb model
  #
  module SillyWalkStrategy

    def included(klass)
      klass.memoize :current_slider
      #klass.memoize :current_slider_setting
      klass.memoize :best_settings
    end

    ##
    # Calculates the current step, and stores the new values
    # for sliders. Also assigns values to this step, so we can 
    # query them later on. 
    #
    def calculate
      freeze_step!(step_settings)
      reload_gql!(step_settings)

      # assign values so we can access them later
      @mission_fitness = fitness
      @gquery_values = gquery_controls.inject({}) {|hsh,gq| hsh.merge gq => gq.future_value }
    end

    ##
    # The (best) settings for the slider_controls. 
    #
    def step_settings
      @step_settings ||= slider_default_settings.merge best_settings
    end

    ##
    # @return [SliderControl] The control that is used in this step.
    #
    def current_slider
      current_index = (self.id - 1) % slider_controls.length
      slider_controls[current_index]
    end


    ##
    # @return [SliderSetting] The settings for the current control.
    #
    def current_slider_setting
      @current_slider_setting ||= best_settings[current_slider]
    end

    ##
    # @return [Hash(SliderControl => SliderSetting)] The settings for the current control.
    #
    def best_settings
      hsh = {}

      current_slider.settings.each do |setting|
        fitness = fitness_of_setting(setting)
        hsh[fitness] = setting
      end
      best_fitness = hsh.keys.sort.first
      hsh[best_fitness]
    end

    ##
    # @return [:up, :down, :none] direction of the current used slider
    #
    def direction_of_slider
      current_slider_setting.direction
    end

    ##
    # @return [Float] fitness for the given settings
    #
    def fitness_of_setting(settings_hash)
      settings = slider_default_settings.merge settings_hash
      reload_gql!(settings)
      fitness
    end
  end
end