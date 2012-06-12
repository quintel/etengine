module MechanicalTurk
  class FactoriesController < BaseController
    def new
    end

    def create
      @generator = Generator.new(params[:json_data])
      render :action => 'show'
    end
  end
end
