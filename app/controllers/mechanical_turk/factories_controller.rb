module MechanicalTurk
  class FactoriesController < BaseController
    def new
    end

    def create
      @turkey_factory = Factory.new(params[:json_data])
      @settings = @turkey_factory.settings
      @results = @turkey_factory.charts
      render :action => 'show'
    end
  end
end
