class AddFirstPartyColumnToOauthApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :oauth_applications, :first_party, :boolean,
      default: false, null: false, after: :confidential
  end
end
