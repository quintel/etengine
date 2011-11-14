class GraphsController < ApplicationController
  def show
    params[:blueprint_id] ||= 'latest'
    params[:region_code] ||= 'nl'
    @blueprint_layout = BlueprintLayout.first
  end
end