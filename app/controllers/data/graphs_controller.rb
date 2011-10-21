class Data::GraphsController < Data::BaseController
  before_filter :load_graph, :only => [:show, :groups, :edit, :destroy, :updated]
  set_tab :graphs

  def new
    @graph = Graph.new
  end

  def chart
    render :layout => false
  end

  def index
    @graphs = Graph.find(:all, :order=>'id desc')
    @csv_importer = CsvImporter.new
  end

  def checks

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

  def groups
    if @graph
      Current.gql = @graph.gql
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

  ##
  # Expects a zip file with a folder (folder name = region_code) for each country/region.
  # TODO: refactor
  #
  def import
    @csv_importer = CsvImporter.new(params[:csv_importer])
    if !@csv_importer.valid?
      @graphs = []
      render :index and return
    end
    raise 'version not defined' if params[:csv_import][:version].blank?
    require 'zip/zip'
    version = params[:csv_import][:version]
    file = params[:csv_import][:zip_file]
    version_path = "import/#{version}"

    Zip::ZipFile.open(file.tempfile) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(version_path, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end

    countries = Dir.entries(version_path).reject{|p| p.include?('MACOS')}.select{|country_dir|
      # check that file is directory. excluding: "." and ".."
      File.directory?("#{version_path}/#{country_dir}") and !country_dir.match(/^\./)
    }

    csv_import = CsvImport.new(version, countries.first)
    blueprint = csv_import.create_blueprint
    blueprint.update_attribute :description, params[:csv_import][:description]

    countries.each do |country|
      csv_import = CsvImport.new(version, country)
      dataset = csv_import.create_dataset(blueprint.id, country)
      Graph.create :blueprint_id => blueprint.id, :dataset_id => dataset.id
    end
    Rails.cache.clear
    redirect_to data_graphs_url
  end

  protected

    def load_graph
      @graph = Graph.find(params[:graph_id] || params[:id])
      Current.graph = @graph
    end
end
