module Opt
  class ControlFactory
    def self.create(*args)
      object = args.first
      params = args[1..-1]
      if object.is_a?(Input)
        if object.share_group.present?
          Opt::SliderGroupControl.new(*args)
        else
          Opt::SliderControl.new(*args)
        end
      elsif object.is_a?(Gquery)
        Opt::GqueryControl.new(*args)
      else
        raise "ControlFactory: no factory found"
      end
    end
  end
end