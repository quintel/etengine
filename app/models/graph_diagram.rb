class GraphDiagram
  attr_accessor :nodes, :nodes, :g

  def initialize(nodes, svg_path = nil)
    require 'graphviz'
    @svg_path = svg_path
    self.nodes = {}
    self.nodes = nodes.uniq
    @g = GraphViz.new( :G, :type => :digraph )
    draw_nodes
    draw_edges
  end

  def to_png
    @g.output( :png => String )
  end

  def to_svg
    @g.output( :svg => String )
  end

  private
    def draw_nodes
      nodes.each do |node|
        smiley = case node.query.demand_expected?
        when nil
          "?"
        when true
          "&#x263A;"
        when false
          "&#x2639;"
        end
        d = (node.query.demand / 10**9).round(3) rescue ''
        pd = (node.primary_demand / 10**9).round(3) rescue ''
        co =  (node.primary_co2_emission / 10**9).round(3) rescue ''
        nodes[node] = @g.add_node("#{node.to_s} \n (#{d}) [#{pd} / co2: #{co}] #{smiley}", node_settings(node))
      end
    end

    def draw_edges
      nodes.map(&:input_edges).flatten.each do |edge|
        p = nodes[edge.lft_node]
        # don't draw if no child anymore.
        if p and c = nodes[edge.rgt_node]
          @g.add_edge p, c, edge_settings(edge)
        end
      end
    end

    def node_settings(node)
      group = [:primary_energy_demand, :useful_demand] & node.groups
      fillcolor = node.output_edges.empty? ? '#dddddd' : nil
      hsh = {
        :shape => 'box',
        :group => group,
        :fillcolor => fillcolor
      }

      hsh[:href] = "#{@svg_path}#{node.key}.svg" if @svg_path

      if node.demand.nil?
        hsh[:color] = '#ff0000'
      end

      hsh
    end

    def edge_settings(edge)
      opts = {}
      share = nil
      colors = {
        :electricity      => '#009900',
        :useable_heat     => '#660000',
        :natural_gas      => '#000099',
        :low_caloric_gas  => '#000099',
        :high_caloric_gas => '#000099',
        :bio_gas          => '#000099'      }
      if edge.share
        share = "#{edge.share} "
      else
        opts[:color] = '#ff0000'
      end
      opts[:color] ||= colors[edge.carrier.key]
      val = (edge.value / 10**9).round(3) rescue ''
      opts[:label] = "[#{edge.carrier.id} | #{edge.edge_type.to_s[0..2]} (#{share})] #{val}"

      opts
    end
end
