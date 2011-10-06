class Data::GqlController < Data::BaseController
  set_tab :gql

  def index
  end

  def search
    @gqueries = []
    @inputs   = []
    @query_table_cells = []

    @q = params[:q]

    unless @q.blank?
      @gqueries          = Gquery.name_or_query_contains(@q)
      @inputs            = Input.embedded_gql_contains(@q)
      @query_table_cells = QueryTableCell.embedded_gql_contains(@q)
    end
  end
end
