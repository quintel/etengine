# frozen_string_literal: true

module Identity
  module IdentityController
    extend ActiveSupport::Concern

    included do
      layout 'identity'
      before_action :authenticate_user!
    end
  end
end
