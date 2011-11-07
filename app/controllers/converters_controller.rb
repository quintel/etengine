class ConvertersController < ApplicationController
  def index
    @converters = Converter.all
  end
  
  def show
    @converter = Converter.find params[:id]
  end
end