class Data::GqlController < Data::BaseController
  def index
  end

  def search
    @gqueries = []
    @inputs   = []
    @query_table_cells = []

    @q = params[:q]

    unless @q.blank?
      @gqueries          = Gquery.name_or_query_contains(@q)
      @query_table_cells = QueryTableCell.embedded_gql_contains(@q)
    end
  end

  def log
    file = Rails.root.join('log/gql.log')
    File.truncate(file, 0) if params[:reset]
    lines = IO.readlines(file)
    lines = lines.grep(Regexp.new(params[:filter])) if params[:filter]
    @log_contents = lines.join
  end
end
