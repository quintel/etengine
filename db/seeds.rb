require 'active_record/fixtures'

Dir[Rails.root.join("db/seed", "*.{yml,csv}").to_s].each do |file|
  Fixtures.create_fixtures("db/seed", File.basename(file, '.*'))
end

password = SecureRandom.hex[0..8]

User.create!(
  name:                  'Admin',
  email:                 'admin@quintel.com',
  password:              password,
  password_confirmation: password,
  role:                  Role.create(id: 1, name: 'admin')
)

puts "Created admin user admin@quintel.com with password: #{ password }"
