class ConvertersController < ApplicationController
  def show
    @graph = Graph.latest_from_country('nl')
    @graph.gql.prepare
    converter_id = Converter.full_keys[params[:id].to_sym]
    @converter = Converter.find converter_id
    @converter_present = @graph.gql.present_graph.graph.converter(@converter.id)
    @converter_future  = @graph.gql.future_graph.graph.converter(@converter.id)
    
    render :layout => false
  end
end