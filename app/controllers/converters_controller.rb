class ConvertersController < ApplicationController
  def index
    @converters = Converter.all
  end
  
  def show
    @graph = Graph.latest_from_country('nl')
    # We have to assign the gql to manually Current
    # DEBT: this is probablye not needed anymore. instead assign Current.graph = @graph
    Current.gql = @graph.gql
    
    Current.gql.prepare
    @converter = Converter.find params[:id]
    @converter_present = @graph.gql.present_graph.graph.converter(@converter.id)
  end
end