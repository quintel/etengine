class Api::InputsController < ApplicationController
  respond_to :xml

  before_filter :find_input, :only => [:show]

  def index
    respond_with(@inputs = Input.all)
  end

  def show
    respond_with(@input)
  end

  private
  
    def find_input
      @input = Input.find(params[:id])
    end
end