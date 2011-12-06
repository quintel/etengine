class Data::GraphsController < Data::BaseController
  set_tab :graphs

  def index
    @graphs = []
    @csv_importer = CsvImporter.new
  end

  def show
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

  # Expects a zip file with a folder (folder name = region_code) for each country/region.
  def import
    @csv_importer = CsvImporter.new(params[:csv_importer])

    if !@csv_importer.valid?
      @graphs = []
      render :index and return
    end
    
    begin
      exit_status = @csv_importer.process!
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Invalid object: #{e.message}, #{e.record.attributes.to_json}"
      exit_status = false
    rescue Exception => e
      flash.now[:alert] = "An error occurred: #{e.message}"
      exit_status = false
    end

    if exit_status
      Rails.cache.clear
      redirect_to data_graphs_url, :notice => "File Imported"
    else
      @graphs = []
      render :index
    end
  end
end
