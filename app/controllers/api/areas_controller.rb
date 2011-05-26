class Api::AreasController < ApplicationController
  respond_to :xml

  before_filter :find_area, :only => [:show]

  def index
    scope = Area.scoped
    scope = scope.country(params[:country]) if params[:country]
    respond_with(@areas = scope.all)
  end

  def show
    respond_with(@area)
  end

  private
    def find_area
      @area = Area.find(params[:id])
    end
end