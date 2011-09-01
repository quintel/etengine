class Data::BlueprintModelsController < Data::BaseController
  def index
    @blueprint_models = BlueprintModel.all
  end
end
