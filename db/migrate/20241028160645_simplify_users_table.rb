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
end
