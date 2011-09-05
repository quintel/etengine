module Sweepers
  class Input < ActionController::Caching::Sweeper
    observe ::Input
    
    def after_save(record)
      expire_fragment 'input_list'
    end
  end
end