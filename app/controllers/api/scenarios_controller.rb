class Api::ScenariosController < ApplicationController
  respond_to :xml

  def index
    respond_with(@scenarios = Scenario.where(:in_start_menu => true))
  end

  def show
    respond_with(@scenario = Scenario.find(params[:id]))
  end
end