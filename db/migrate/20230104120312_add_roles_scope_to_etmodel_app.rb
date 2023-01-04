# frozen_string_literal: true

class AddRolesScopeToEtmodelApp < ActiveRecord::Migration[7.0]
  OLD_SCOPES = 'openid public profile email scenarios:read scenarios:write scenarios:delete'
  NEW_SCOPES = 'openid public profile email roles scenarios:read scenarios:write scenarios:delete'

  def up
    apps.find_each do |app|
      app.update!(scopes: NEW_SCOPES)
    end
  end

  def down
    apps.find_each do |app|
      app.update!(scopes: OLD_SCOPES)
    end
  end

  private

  def apps
    OAuthApplication.where(name: ['ETModel', 'ETModel (Local)'])
  end
end
