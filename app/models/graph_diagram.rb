class GraphDiagram
  attr_accessor :nodes, :converters, :g

  def initialize(converters, svg_path = nil)
    require 'graphviz'
    @svg_path = svg_path
    self.nodes = {}
    self.converters = converters.uniq
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
      converters.each do |converter|
        smiley = case converter.query.demand_expected?
        when nil
          "?"
        when true
          "&#x263A;"
        when false
          "&#x2639;"
        end
        d = (converter.query.demand / 10**9).round(3) rescue ''
        pd = (converter.primary_demand / 10**9).round(3) rescue ''
        co =  (converter.primary_co2_emission / 10**9).round(3) rescue ''
        nodes[converter] = @g.add_node("#{converter.to_s} \n (#{d}) [#{pd} / co2: #{co}] #{smiley}", node_settings(converter))
      end
    end

    def draw_edges
      converters.map(&:input_links).flatten.each do |link|
        p = nodes[link.lft_converter]
        # don't draw if no child anymore.
        if p and c = nodes[link.rgt_converter]
          @g.add_edge p, c, edge_settings(link)
        end
      end
    end

    def node_settings(converter)
      group = [:primary_energy_demand, :useful_demand] & converter.groups
      fillcolor = converter.output_links.empty? ? '#dddddd' : nil
      hsh = {
        :shape => 'box',
        :group => group,
        :fillcolor => fillcolor
      }

      hsh[:href] = "#{@svg_path}#{converter.id}.svg" if @svg_path

      if converter.demand.nil?
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
