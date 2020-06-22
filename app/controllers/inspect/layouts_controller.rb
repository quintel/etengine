class Inspect::LayoutsController < Inspect::BaseController
  before_action :find_models, :only => [:show, :edit]

  helper_method :attributes_for_json, :positions

  skip_authorize_resource :only => :show

  def show
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
    end
  end

  def yaml
    response.headers['Content-Disposition'] = 'attachment; filename="node_positions.yml"'
    response.headers['Content-Type']        = 'application/x-yaml'

    render plain: positions.to_yaml
  end

  def edit
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
    end
  end

  def update
    if params[:node_positions].present?
      positions.update(params[:node_positions].permit!)
    end

    render plain: '', layout: nil
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
    attrs << Qernel::NodeApi::ATTRIBUTES_USED.sort if params[:action] == 'edit'
    attrs.flatten
  end

  def find_models
    @nodes = @gql.present_graph.nodes
  end

  def graph_to_json(graph)
    graph.nodes.inject({}) do |hsh, c|
      attr_hash = attributes_for_json.inject({}) do |h, key|
        v = c.query.send(key)
        h.merge key => auto_number(v)
      end
      hsh.merge c.key => attr_hash
    end
  end

  def positions
    @positions ||= NodePositions.new(Atlas.data_dir.join('config/node_positions.yml'))
  end

  def auto_number(n)
    self.class.helpers.auto_number(n)
  end

end
