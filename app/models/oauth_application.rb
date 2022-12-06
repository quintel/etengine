# frozen_string_literal: true

class OAuthApplication < ApplicationRecord
  include Doorkeeper::Orm::ActiveRecord::Mixins::Application

  validates :uri, presence: true, 'doorkeeper/redirect_uri': true
end
