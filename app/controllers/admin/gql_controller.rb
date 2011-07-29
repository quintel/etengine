module Admin
  class GqlController < BaseController
    set_tab :gql
    
    def index
    end
    
    def search
      @gqueries = []
      @inputs   = []
      
      @q = params[:q]
      
      unless @q.blank?
        @gqueries = Gquery.contains(@q)
        @inputs   = Input.contains(@q)
      end
    end
  end
end