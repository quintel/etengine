class Construction::GraphsController < Construction::ConstructionController


  def index
    @graphs = Graph.ordered
  end

  def new
    @graph = Graph.new()
  end

  def create
    if params[:copy_graph_id]
      original = Graph.find(params[:copy_graph_id])
      graph = original.copy_graph!
      if graph.update_attributes(params[:graph])
        flash[:notice] = 'Graph Created'
        redirect_to construction_graphs_url
      end
    else
      flash[:notice] = 'Specify a graph to copy from'
      render :action => 'new'
    end
  end
end
