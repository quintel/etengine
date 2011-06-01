class Admin::ConvertersController  < Admin::AdminController
  before_filter :find_blueprint_model
  before_filter :find_latest_blueprint

  def index
    @converters = @blueprint.converter_records
  end

  def show
    redirect_to edit_construction_converter_url(params[:id])
  end

  def edit
    @converter = @blueprint.converter_records.find(params[:id])
  end

  def new
    @converter = @blueprint.converter_records.build
  end

  def create
    @converter = Converter.new(params[:converter])
    if @converter.save
      @blueprint.converter_records << @converter
      redirect_to edit_construction_converter_path(:id => @converter)
    else
      render :action => 'new'
    end
  end
end
