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
      nodes.map(&:input_links).flatten.each do |link|
        p = nodes[link.lft_node]
        # don't draw if no child anymore.
        if p and c = nodes[link.rgt_node]
          @g.add_edge p, c, edge_settings(link)
        end
      end
    end

    def node_settings(node)
      group = [:primary_energy_demand, :useful_demand] & node.groups
      fillcolor = node.output_links.empty? ? '#dddddd' : nil
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

    def edge_settings(link)
      opts = {}
      share = nil
      colors = {
        :electricity      => '#009900',
        :useable_heat     => '#660000',
        :natural_gas      => '#000099',
        :low_caloric_gas  => '#000099',
        :high_caloric_gas => '#000099',
        :bio_gas          => '#000099'      }
      if link.share
        share = "#{link.share} "
      else
        opts[:color] = '#ff0000'
      end
      opts[:color] ||= colors[link.carrier.key]
      val = (link.value / 10**9).round(3) rescue ''
      opts[:label] = "[#{link.carrier.id} | #{link.link_type.to_s[0..2]} (#{share})] #{val}"

      opts
    end
end
