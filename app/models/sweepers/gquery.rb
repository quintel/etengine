module Sweepers
  class Gquery < ActionController::Caching::Sweeper
    observe ::Gquery
    
    def after_save(record)
      expire_fragment 'gquery_list'        # sidebar panel
      expire_fragment 'gquery_index_table' # data/gqueries#index
    end
  end
end