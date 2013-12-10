class SwitchToBcrypt < ActiveRecord::Migration
  # Migrates old SHA512+Salt passwords to use BCrypt. Since we can't know what
  # everyone's password is, we're going to keep the old salt but re-hash their
  # hashed password with BCrypt.
  #
  # When a user logs in, we'll check their password against this new hash, and
  # if valid, migrate them to the "proper" BCrypt column.
  def up
    change_table(:users) do |t|
      # This will store a BCrypted version of the old hashed password.
      t.string :old_crypted_password, :null => true

      # This will store the real BCrypt password, after the user successfully
      # logs in the first time.
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0, :null => false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
    end

    User.reset_column_information

    # Re-hash the SHA512 passwords with BCrypt.

    say_with_time 'Converting old attributes (and re-hashing passwords)' do
      User.all.each do |user|
        user.update_attributes!(
          current_sign_in_ip:   user.current_login_ip,
          current_sign_in_at:   user.current_login_at,
          sign_in_count:        user.login_count,
          last_sign_in_at:      user.last_login_at,
          last_sign_in_ip:      user.last_login_ip,
          old_crypted_password: BCrypt::Password.create(user.crypted_password)
        )
      end
    end

    # And finally delete the old columns.
    remove_column :users, :crypted_password
    remove_column :users, :persistence_token
    remove_column :users, :perishable_token
    remove_column :users, :login_count
    remove_column :users, :failed_login_count
    remove_column :users, :last_request_at
    remove_column :users, :current_login_at
    remove_column :users, :last_login_at
    remove_column :users, :current_login_ip
    remove_column :users, :last_login_ip
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
