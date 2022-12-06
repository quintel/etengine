class CreatePersonalAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :personal_access_tokens do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :oauth_access_token, null: false, foreign_key: true, index: { unique: true }
      t.string :name
      t.datetime :last_used_at
    end

    change_column :oauth_access_tokens, :application_id, :bigint,
      null: true, after: :resource_owner_id
  end
end
