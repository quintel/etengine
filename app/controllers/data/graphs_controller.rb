class Data::GraphsController < Data::BaseController
  before_filter :load_graph, :only => [:show, :edit, :destroy]
  set_tab :graphs

  def new
    @graph = Graph.new
  end

  def index
    @graphs = Graph.find(:all, :order=>'id desc')
    @csv_importer = CsvImporter.new
  end

  def show
    # this fails right now, turned of temporarily
    # if @graph
    #   Current.gql = @graph.gql
    # end
    if params[:compare_to] and @compare_graph = Graph.find(params[:compare_to])
      @compare_graph.to_qernel.calculate
    end
    respond_to do |format|
      format.json do
        render :json => Current.gql.present_graph.graph.converters.inject({}) {|hsh,c| hsh.merge c.id => {:demand => ((c.proxy.demand / 1000000).round(1) rescue nil)} }
      end
      format.html    { render }
    end
  end

  # Taken from the construction namespace
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

  def destroy
    if @graph.destroy
      flash[:notice] = 'Graph deleted'
      redirect_to :back
    end
  end

  # Expects a zip file with a folder (folder name = region_code) for each country/region.
  def import
    @csv_importer = CsvImporter.new(params[:csv_importer])
    if !@csv_importer.valid?
      @graphs = []
      render :index and return
    end
    
    begin
      status = @csv_importer.process!
      Rails.cache.clear
      redirect_to data_graphs_url, :notice => "File Imported"
    rescue Exception => e
      flash.now[:alert] = "An error occurred: #{e.message}"
      @graphs = []
      render :index
    end
  end

  protected

    def load_graph
      @graph = Graph.find(params[:graph_id] || params[:id])
      Current.graph = @graph
    end
end
