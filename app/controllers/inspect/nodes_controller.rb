# frozen_string_literal: true

require_relative 'graph_scoped'

# Shows informations about nodes in a graph.
class Inspect::NodesController < Inspect::BaseController
  include Inspect::GraphScoped

  layout 'application'

  skip_authorize_resource :only => :show

  def index
    all = present_graph.nodes
    all.select!{|c| c.key.to_s.include?(params[:q])} if params[:q]
    all.select!{|c| c.groups.include?(params[:group].to_sym) } if params[:group].present?

    @nodes = Kaminari.paginate_array(all.sort_by(&:key)).
      page(params[:page]).per(50)
  end

  def show
    key = params[:id].to_sym
    @qernel_graph = present_graph
    @node_present = present_graph.graph.node(key.to_sym)
    @node_future  = future_graph.graph.node(key.to_sym)

    if @node_present.nil?
      render_not_found('node')
      return
    end

    @node_api   = @node_present.node_api
    @serializer = NodeSerializer.new(@node_present, @node_future)

    respond_to do |format|
      format.html { render :layout => true }
      format.png  { render :plain => diagram.to_png }
      format.svg  { render :plain => diagram.to_svg }
    end
  end

  protected

  def diagram
    depth = params[:depth]&.to_i || 3
    base_url = "/inspect/#{@api_scenario.id}/graphs"
    node = params[:graph] == 'future' ? @node_future : @node_present
    node.to_image(depth, base_url)
  end
end
