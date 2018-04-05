module Qernel::Plugins
  class Network
    include Plugin

    def self.enabled?(graph)
      MeritOrder.enabled?(graph)
    end

    def run(_lifecycle)
    end
  end
end
