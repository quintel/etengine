# frozen_string_literal: true

module Users
  class ProfileController < ApplicationController
    layout 'identity'
    before_action :authenticate_user!
  end
end
