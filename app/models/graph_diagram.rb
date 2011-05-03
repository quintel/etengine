class GraphDiagram
  attr_accessor :nodes, :converters, :g

  def initialize(converters)
    require 'graphviz'
    self.nodes = {}
    self.converters = converters.uniq
    @g = GraphViz.new( :G, :type => :digraph )
  end

  def generate(filename = 'out')
    draw_nodes
    draw_edges
    write(filename)
  end

private
  def write(filename = 'out')
    @g.output( :png => "#{filename}.png" )
    @g.output( :dot => "#{filename}.dot" )
  end

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
      p = nodes[link.parent]
      # don't draw if no child anymore.
      if p and c = nodes[link.child]
        @g.add_edge p, c, edge_settings(link)
      end
    end
  end

  def node_settings(converter)
    group = [:primary_energy_demand, :useful_demand] & converter.groups.map(&:key)
    fillcolor = converter.output_links.empty? ? '#dddddd' : nil
    hsh = {
      :shape => 'box',
      :group => group,
      :fillcolor => fillcolor
    }

    if converter.demand.nil?
      hsh[:color] = '#ff0000'
    end

    hsh
  end

  def edge_settings(link)
    opts = {}
    share = nil
    colors = {
      :electricity => '#009900',
      :useable_heat => '#660000',
      :natural_gas => '#000099',
      :low_caloric_gas => '#000099',
      :high_caloric_gas => '#000099',
      :bio_gas => '#000099',
      :hot_water => '#990099'
    }
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
