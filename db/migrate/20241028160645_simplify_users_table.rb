class SimplifyUsersTable < ActiveRecord::Migration[7.0]
  def up
    # Change existing primary key to bigint
    execute "ALTER TABLE users MODIFY id BIGINT AUTO_INCREMENT"

    # Remove unnecessary columns from users table
    change_table :users, bulk: true do |t|
      t.remove :email, :encrypted_password, :legacy_password_salt,
               :reset_password_token, :reset_password_sent_at, :remember_created_at, :sign_in_count,
               :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip,
               :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email, :deleted_at
    end

    # Remove foreign key constraints before dropping tables
    remove_foreign_key :oauth_access_grants, :oauth_applications
    remove_foreign_key :oauth_access_tokens, :oauth_applications
    remove_foreign_key :personal_access_tokens, :oauth_access_tokens
    remove_foreign_key :personal_access_tokens, :users
    remove_foreign_key :staff_applications, :users
    remove_foreign_key :oauth_openid_requests, :oauth_access_grants

    # Drop specified tables and any related foreign keys
    drop_table :staff_applications, if_exists: true
    drop_table :oauth_applications, if_exists: true
    drop_table :oauth_access_tokens, if_exists: true
    drop_table :oauth_access_grants, if_exists: true
  end

  def down
    # Revert primary key to integer in users table
    execute "ALTER TABLE users MODIFY id INT AUTO_INCREMENT PRIMARY KEY"

    # Re-add removed columns in users table with original configurations
    change_table :users, bulk: true do |t|
      t.string :email, default: "", null: false
      t.string :encrypted_password, default: "", null: false
      t.string :legacy_password_salt
      t.boolean :private_scenarios, default: false
      t.boolean :admin, default: false, null: false
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
      t.datetime :deleted_at
    end

    # Recreate the dropped tables if necessary
    create_table :staff_applications, id: :bigint do |t|
      t.string :name, null: false
      t.bigint :user_id, null: false
      t.bigint :application_id, null: false
      t.index ["application_id"], name: "index_staff_applications_on_application_id"
      t.index ["user_id", "name"], name: "index_staff_applications_on_user_id_and_name", unique: true
      t.index ["user_id"], name: "index_staff_applications_on_user_id"
    end

    create_table :oauth_applications, id: :bigint do |t|
      t.string :name, null: false
      t.string :uid, null: false
      t.string :secret, null: false
      t.string :uri, null: false
      t.text :redirect_uri
      t.string :scopes, default: "", null: false
      t.boolean :confidential, default: true, null: false
      t.boolean :first_party, default: false, null: false
      t.integer :owner_id, null: false
      t.string :owner_type, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
      t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
    end

    create_table :oauth_access_tokens, id: :bigint do |t|
      t.bigint :resource_owner_id
      t.bigint :application_id
      t.string :token, null: false
      t.string :refresh_token
      t.integer :expires_in
      t.datetime :revoked_at
      t.datetime :created_at, null: false
      t.string :scopes
      t.string :previous_refresh_token, default: "", null: false
      t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
      t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
      t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
      t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
    end

    create_table :oauth_access_grants, id: :bigint do |t|
      t.bigint :resource_owner_id, null: false
      t.bigint :application_id, null: false
      t.string :token, null: false
      t.integer :expires_in, null: false
      t.text :redirect_uri, null: false
      t.datetime :created_at, null: false
      t.datetime :revoked_at
      t.string :scopes, default: "", null: false
      t.string :code_challenge
      t.string :code_challenge_method
      t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
      t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
      t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
    end
  end
end
