class Admin::AdminController < ApplicationController
  layout 'admin'
  
  before_filter :restrict_to_admin

  protected
  
    def find_latest_blueprint
      blueprint_model = find_blueprint_model
      @blueprint = blueprint_model.blueprints.latest.first
    end

    def find_blueprint_model
      unless @blueprint_model
        blueprint_model_id = params[:blueprint_model_id]
        @blueprint_model = BlueprintModel.find(blueprint_model_id)
      end
      @blueprint_model
    end
  
end
  