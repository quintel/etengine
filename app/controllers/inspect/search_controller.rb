class Inspect::SearchController < Inspect::BaseController
  layout 'application'
  skip_before_action :initialize_gql, :only => [:index]

  def index
    respond_to do |format|
      format.html do
        if search = params[:search]
          if gquery = Gquery.get(search.strip)
            redirect_to inspect_gquery_path(id: gquery.key)
          elsif Etsource::Loader.instance.energy_graph.node(search)
            redirect_to inspect_node_path(id: search, graph_name: 'energy')
          elsif Etsource::Loader.instance.molecule_graph.node(search)
            redirect_to inspect_node_path(id: search, graph_name: 'molecules')
          else
            initialize_gql
            @gqueries = Gquery.all.select{ |g| g.key.include?(params[:search]) }.sort_by(&:key)
            @energy_nodes = @gql.present_graph.graph.nodes.select!{ |c| c.key.to_s.include?(params[:search]) }.sort_by(&:key)
            @molecule_nodes = @gql.present.molecules.nodes.select!{ |c| c.key.to_s.include?(params[:search]) }.sort_by(&:key)
          end
        end
      end
    end
  end
end
