class Data::GqlController < Data::BaseController
  set_tab :gql

  def index
  end

  def search
    @gqueries = []
    @inputs   = []

    @q = params[:q]

    unless @q.blank?
      @gqueries = Gquery.name_or_query_contains(@q)
      @inputs   = Input.embedded_gql_contains(@q)
    end
  end
end
