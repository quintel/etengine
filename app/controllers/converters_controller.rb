class ConvertersController < ApplicationController
  def index
    @converters = Converter.all
  end
  
  def show
    @graph = Graph.latest_from_country('nl')
    @graph.gql.prepare
    @converter = Converter.find params[:id]
    @converter_present = @graph.gql.present_graph.graph.converter(@converter.id)
    @converter_future = @graph.gql.future_graph.graph.converter(@converter.id)
  end
end