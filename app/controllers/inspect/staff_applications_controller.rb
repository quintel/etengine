# frozen_string_literal: true

module Inspect
  # Updates a staff application with a new URI.
  class StaffApplicationsController < ApplicationController
    def update
      result = CreateStaffApplication.call(
        current_user,
        ETEngine::StaffApplications.find(params[:id]),
        uri: params[:uri].presence
      )

      if result.success?
        flash[:notice] = 'The application was updated.'
      else
        flash[:alert] = result.failure.errors.full_messages.to_sentence
      end

      redirect_to root_path
    end
  end
end
