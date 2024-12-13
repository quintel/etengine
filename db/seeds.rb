require 'active_record/fixtures'

Dir[Rails.root.join("db/seed", "*.{yml,csv}").to_s].each do |file|
  Fixtures.create_fixtures("db/seed", File.basename(file, '.*'))
end

password = SecureRandom.base58(8)

User.create!(
  name:     'Admin',
  admin:    true
)

puts <<~MSG
  +------------------------------------------------------------------------------+
  |         Created admin user admin@example.org with password: #{password}         |
  | Please change this password if you're deploying to a production environment! |
  +------------------------------------------------------------------------------+
MSG

begin
  Scenario.new(Scenario.default_attributes).save(validate: false)
rescue Atlas::ConfigNotFoundError
  # Typically happens in the CI environment due to no config file.
  puts <<~MSG
    Skipping scenario creation, no config file found. Create a
    scenario manually through the Rails console before accessing
    the admin pages.
  MSG
end
