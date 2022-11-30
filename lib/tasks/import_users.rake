# frozen_string_literal: true

desc 'Imports users from an ETModel CSV file'
task import_users: :environment do
  require 'csv'
  require 'yaml'

  admins = Set.new(YAML.load_file('tmp/users/admins.yml'))
  imported_at = Time.zone.now

  maybe = ->(value) { value.presence == 'NULL' ? nil : value }

  User.find_by(email: 'dev@quintel.com')&.destroy
  User.delete_all
  User.connection.execute("ALTER TABLE #{User.table_name} AUTO_INCREMENT = 1;")

  CSV.foreach('tmp/users/users.csv', headers: true) do |row|
    User.insert({
      id: row['id'],
      email: row['email'],
      name: row['name'],
      encrypted_password: row['crypted_password'],
      legacy_password_salt: maybe.call(row['password_salt']),
      admin: admins.include?(row['email']),
      sign_in_count: row['login_count'],
      current_sign_in_at: maybe.call(row['current_login_at']),
      last_sign_in_at: maybe.call(row['last_login_at']),
      current_sign_in_ip: maybe.call(row['current_login_ip']),
      last_sign_in_ip: maybe.call(row['last_login_ip']),
      confirmed_at: imported_at,
      created_at: imported_at,
      updated_at: imported_at
    }, record_timestamps: false)
  end

  dev_user = if (user = User.find_by(email: 'dev@quintel.com'))
    user.update!(admin: true, password: SecureRandom.urlsafe_base64(48))
    user
  else
    User.create!(
      name: 'Quintel Developers',
      email: 'dev@quintel.com',
      password: SecureRandom.urlsafe_base64(48),
      admin: true,
      confirmed_at: Time.zone.now
    )
  end

  dev_user.oauth_applications.create!(
    name: 'Personal Access Tokens',
    scopes: 'public'
  )

  dev_user.oauth_applications.create!(
    name: 'ETModel',
    scopes: 'public'
  )

  dev_user.oauth_applications.create!(
    name: 'Transition Paths',
    scopes: 'public'
  )
end
