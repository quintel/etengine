class CleanUpUserModel < ActiveRecord::Migration[7.0]
  # We're going to clean house and remove the existing users table. We'll be importing the users
  # from ETModel.
  def up
    drop_table :users

    create_table 'users' do |t|
      t.string 'email', default: '', null: false
      t.string 'encrypted_password', default: '', null: false
      t.string 'name', default: '', null: false
      t.boolean 'admin', default: false, null: false
      t.string 'reset_password_token'
      t.datetime 'reset_password_sent_at'
      t.datetime 'remember_created_at'
      t.integer 'sign_in_count', default: 0, null: false
      t.datetime 'current_sign_in_at'
      t.datetime 'last_sign_in_at'
      t.string 'current_sign_in_ip'
      t.string 'last_sign_in_ip'
      t.string 'confirmation_token'
      t.datetime 'confirmed_at'
      t.datetime 'confirmation_sent_at'
      t.string 'unconfirmed_email'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['confirmation_token'], name: 'index_users_on_confirmation_token', unique: true
      t.index ['email'], name: 'index_users_on_email', unique: true
      t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    end

    execute 'UPDATE scenarios SET user_id = NULL'

    change_column 'scenarios', 'user_id', :bigint
    add_foreign_key 'scenarios', 'users'
    add_index 'scenarios', ['user_id']
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
