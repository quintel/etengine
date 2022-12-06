# frozen_string_literal: true

# Relates staff (admin) users to local OAuth applications.
class StaffApplication < ApplicationRecord
  belongs_to :user
  belongs_to :application, class_name: 'OAuthApplication', dependent: :destroy

  validates :name, presence: true
  validates :user, uniqueness: { scope: :name }
end
