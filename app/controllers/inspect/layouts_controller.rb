class Inspect::LayoutsController < Inspect::BaseController
  GRAPHS = %w[energy molecules].freeze

  before_action :find_models, :only => [:show, :edit]

  helper_method :attributes_for_json, :positions
  skip_authorize_resource :only => :show

  before_action :assert_valid_graph

  def show
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
    end
  end

  def yaml
    response.headers['Content-Type'] = 'application/x-yaml'
    response.headers['Content-Disposition'] =
      "attachment; filename=\"#{params[:id]}_node_positions.yml\""

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

  def assert_valid_graph
  end

  def graph(period)
    raise "Invalid graph period: #{period.inspect}" unless %i[future present].include?(period)

    interface = @gql.public_send(period)

    if params[:id] == 'molecules'
      interface.molecules
    else
      interface.graph
    end
  end

  def node_class
  end

  def result
    @result ||= {
      'present' => graph_to_json(graph(:present)),
      'future' => graph_to_json(graph(:future))
    }
  end

  def attributes_for_json
    attrs = ['demand', 'primary_demand']
    attrs << Qernel::NodeApi::Attributes::ATTRIBUTES_USED.sort if params[:action] == 'edit'
    attrs.flatten
  end

  def find_models
    @nodes = graph(:present).nodes
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
    @positions ||=
      NodePositions.new(
        Atlas.data_dir.join("config/#{params[:id]}_node_positions.yml"),
        if params[:id] == 'molecules'
          Atlas::MoleculeNode
        else
          Atlas::EnergyNode
        end
      )
  end

  def auto_number(n)
    self.class.helpers.auto_number(n)
  end
end
