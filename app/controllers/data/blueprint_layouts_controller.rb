class Data::BlueprintLayoutsController < Data::BaseController
  before_filter :find_models, :only => [:show, :edit]

  helper_method :attributes_for_json

  def index
    @blueprint_layouts = BlueprintLayout.find(:all)
  end

  def show
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
      format.js   { render :layout => false }
    end
  end
  alias_method :edit, :show


  def new
    @blueprint_layout = BlueprintLayout.new
  end

  def create
    @blueprint_layout = BlueprintLayout.new(params[:blueprint_layout])
    if @blueprint_layout.save
      redirect_to data_blueprint_layouts_path
    else
      render :action => 'new'
    end
  end

private
  def result
    @result ||= {
      'future' => graph_to_json(Current.gql.future_graph),
      'present' => graph_to_json(Current.gql.present_graph)
    }
  end

  def attributes_for_json
    attrs = ['demand', 'primary_demand']
    #attrs << Qernel::ConverterApi.calculation_methods.sort
    attrs << Qernel::ConverterApi::ATTRIBUTES_USED.sort
    attrs.flatten
  end

  def find_models
    @blueprint_layout = BlueprintLayout.find(params[:id])
    @converter_positions = @blueprint_layout.converter_positions.inject({}) {|hsh, cp| hsh.merge cp.converter_id => cp}
  end

  def graph_to_json(graph)
    graph.converters.inject({}) do |hsh, c|
      attr_hash = attributes_for_json.inject({}) {|h, key| h.merge key => self.class.helpers.auto_number(c.query.send(key)) }
      hsh.merge c.id => attr_hash
    end
  end

end
