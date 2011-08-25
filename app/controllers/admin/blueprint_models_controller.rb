module Admin
  class BlueprintModelsController < BaseController
    def index
      @blueprint_models = BlueprintModel.all
    end

  end
end