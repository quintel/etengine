module MechanicalTurk
  class TurksController < BaseController
    def index
      @turks = Turk.all
    end

    def show
      @turk = Turk.get(params[:id])
    end
  end
end
