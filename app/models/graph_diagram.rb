# frozen_string_literal: true

# Given Qernel::Node instances, draws a visual representation of the nodes using GraphViz.
class GraphDiagram
  EDGE_COLORS = {
    electricity: '#009900',
    useable_heat: '#660000',
    natural_gas: '#000099',
    low_caloric_gas: '#000099',
    high_caloric_gas: '#000099',
    bio_gas: '#000099'
  }.freeze

  def initialize(nodes, svg_path = nil)
    require 'graphviz'

    @svg_path = svg_path
    @collection = {}
    @nodes = nodes.uniq
    @g = GraphViz.new(:G, type: :digraph)

    draw_nodes
    draw_edges
  end

  def to_png
    @g.output(png: String)
  end

  def to_svg
    @g.output(svg: String)
  end

  private

  def draw_nodes
    @nodes.each do |node|
      smiley = node_smiley(node)
      demand = safe_node_attribute(node, :demand)

      if node.graph.name == :energy
        primary_demand = safe_node_attribute(node, :primary_demand)
        co2 = safe_node_attribute(node, :primary_co2_emission)
        attrs = " [#{primary_demand} / co2: #{co2}]"
      else
        attrs = ''
      end

      @collection[node] = @g.add_node(
        "#{node.key} \n (#{demand})#{attrs} #{smiley}",
        node_settings(node)
      )
    end
  end

  def draw_edges
    @nodes.map(&:input_edges).flatten.each do |edge|
      left = @collection[edge.lft_node]

      if left && (right = @collection[edge.rgt_node])
        @g.add_edge(left, right, edge_settings(edge))
      end
    end
  end

  def node_settings(node)
    settings = {
      fillcolor: node.output_edges.empty? ? '#dddddd' : nil,
      group: %i[primary_energy_demand useful_demand] & node.groups,
      shape: 'box'
    }

    settings[:href] = "#{@svg_path}/#{node.graph.name}/nodes/#{node.key}.svg" if @svg_path
    settings[:color] = '#ff0000' if node.demand.nil?

    settings
  end

  def node_smiley(node)
    case node.query.demand_expected?
    when nil then '?'
    when true then '&#x263A;'
    when false then '&#x2639;'
    end
  end

  def safe_node_attribute(node, attribute)
    (node.query.public_send(attribute) / 10**9).round(3)
  rescue RuntimeError
    ''
  end

  def edge_settings(edge)
    settings = {}
    share = nil

    if edge.share
      share = "#{edge.share} "
    else
      settings[:color] = '#ff0000'
    end

    settings[:color] ||= EDGE_COLORS[edge.carrier.key]

    val =
      begin
        (edge.value / 10**9).round(3)
      rescue StandardError
        ''
      end

    settings[:label] = "[#{edge.carrier.id} | #{edge.edge_type.to_s[0..2]} (#{share})] #{val}"

    settings
  end
end
