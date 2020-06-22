class Inspect::SearchController < Inspect::BaseController
  layout 'application'
  skip_before_action :initialize_gql, :only => [:index]

  def index
    respond_to do |format|
      format.js { render :layout => false}
      format.html do
        if search = params[:search]
          if gquery = Gquery.get(search.strip)
            redirect_to inspect_gquery_path(id: gquery.key)
          elsif Etsource::Loader.instance.graph.node(search)
            redirect_to inspect_node_path(id: search)
          else
            initialize_gql
            @gqueries = Gquery.all.select{|g| g.key.include?(params[:search])}
            @nodes = @gql.present_graph.graph.nodes.select!{|c| c.key.to_s.include?(params[:search])}
          end
        end
      end
    end
  end
end
