class Data::LayoutsController < Data::BaseController
  before_filter :find_models, :only => [:show, :edit]

  helper_method :attributes_for_json, :positions

  skip_authorize_resource :only => :show

  def show
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
    end
  end

  def yaml
    response.headers['Content-Disposition'] = 'attachment; filename="converter_positions.yaml"'
    response.headers['Content-Type']        = 'application/x-yaml'

    render text: positions.to_yaml
    # respond_to do |format|
      # format.html { render :layout => 'blueprint_layout' }
      # format.json { render text: positions.to_yaml  }
    # end
  end

  def edit
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
    end
  end

  def update
    if params[:converter_positions].present?
      positions.update(params[:converter_positions])
    end

    render :text => ''
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
    attrs = ['demand', 'primary_demand']
    attrs << Qernel::ConverterApi::ATTRIBUTES_USED.sort if params[:action] == 'edit'
    attrs.flatten
  end

  def find_models
    @converters = @gql.present_graph.converters
  end

  def graph_to_json(graph)
    graph.converters.inject({}) do |hsh, c|
      attr_hash = attributes_for_json.inject({}) do |h, key|
        v = c.query.send(key)
        h.merge key => auto_number(v)
      end
      hsh.merge c.key => attr_hash
    end
  end

  def positions
    ConverterPositions.new(Rails.root.join('config/converter_positions.yml'))
  end

  def auto_number(n)
    self.class.helpers.auto_number(n)
  end

end
