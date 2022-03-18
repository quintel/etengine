require 'active_record/fixtures'

Dir[Rails.root.join("db/seed", "*.{yml,csv}").to_s].each do |file|
  Fixtures.create_fixtures("db/seed", File.basename(file, '.*'))
end

password = SecureRandom.base58(8)

User.create!(
  name:                  'Admin',
  email:                 "admin@example.org",
  password:              password,
  password_confirmation: password,
  role:                  Role.create(id: 1, name: 'admin')
)

puts <<~MSG
  +------------------------------------------------------------------------------+
  |         Created admin user admin@example.org with password: #{password}         |
  | Please change this password if you're deploying to a production environment! |
  +------------------------------------------------------------------------------+
MSG
