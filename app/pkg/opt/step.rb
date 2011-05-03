module Opt
  ##
  # Controls one optimizer iteration and stores its values.
  #
  #
  class Step
    extend ActiveSupport::Memoizable

    include SillyWalkStrategy

    attr_reader :mission, :id, :gquery_values, :mission_fitness, :steps

    def initialize(mission)
      @mission = mission
      @id = @mission.next_step_increment!
    end

    %w[
      slider_controls 
      gquery_controls 
      fitness 
      reload_gql!
      freeze_step! 
      slider_controls
    ].each do |delegate_method|
      ##
      # Delegate method to mission
      #
      define_method delegate_method do |*args|
        mission.send(delegate_method, *args)
      end
    end

    ##
    # The slider settings of the current (untouched) step. 
    # Equals the settings of last_step. Overwrite settings
    # in this Hash with your custom ones defined in the 
    # strategy.
    #
    # @return [Hash] SliderControl => SliderSetting
    #
    def slider_default_settings
      @slider_default_settings ||= slider_controls.inject({}) do |hsh, slider_control|
        setting = slider_control.default_setting
        hsh.merge slider_control => setting
      end
    end


  end
end


