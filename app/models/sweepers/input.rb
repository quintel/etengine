module Sweepers
  class Input < ActionController::Caching::Sweeper
    observe ::Input
    
    def after_save(record)
      expire_fragment 'inputs_autocomplete_map_cache'
    end
  end
end