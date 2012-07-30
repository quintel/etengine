class Data::BlueprintLayoutsController < Data::BaseController
  before_filter :find_models, :only => [:show, :edit]

  helper_method :attributes_for_json

  def index
    @blueprint_layouts = BlueprintLayout.find(:all)
    render :layout => 'application'
  end

  def show
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
      format.js   { render :layout => false }
    end
  end

  def edit
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
      format.js   { render :layout => false }
    end
  end


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
    unless @result
      @result = {
        'future' => graph_to_json(@gql.future_graph),
        'present' => graph_to_json(@gql.present_graph)
      }
    end
    @result
  end

  def attributes_for_json
    attrs = ['demand', 'primary_demand', 'energy_balance_group']
    attrs << Qernel::ConverterApi::ATTRIBUTES_USED.sort if params[:action] == 'edit'
    attrs.flatten
  end

  def find_models
    @blueprint_layout = BlueprintLayout.find(params[:id])
    @converter_positions = ConverterPosition.all.inject({}) {|hsh, cp| hsh.merge cp.converter_id => cp}
  end

  def graph_to_json(graph)
    graph.converters.inject({}) do |hsh, c|
      attr_hash = attributes_for_json.inject({}) do |h, key| 
        v = c.query.send(key)
        h.merge key => auto_number(v)
      end
      hsh.merge c.excel_id => attr_hash
    end
  end

  def auto_number(n)
    self.class.helpers.auto_number(n)
  end

end
