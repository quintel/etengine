namespace :db do
  desc 'Dumps the entire database to a gzipped SQL file'
  task dump_sql: :environment do
    config   = Rails.configuration.database_configuration
    host     = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]

    dump_to  = "#{ database }_#{ Time.now.utc.to_formatted_s(:number) }.sql.gz"

    system([
      'mysqldump', "--user #{ username }",
      password ? "--password=#{ password }" : nil,
      "--host=#{ host }", "#{ database }", "| gzip > tmp/#{ dump_to }"
    ].compact.join(' '))

    puts "tmp/#{ dump_to }"
  end

  desc 'Dumps staff applications to be reloaded later'
  task dump_staff_applications: :environment do
    FileUtils.rm_rf('tmp/staff_applications.yml')

    applications = []
    staff_applications = []
    tokens = []

    StaffApplication.all.includes(:application).map do |app|
      applications.push(app.application.attributes)
      staff_applications.push(app.attributes)
      tokens.push(*app.application.access_tokens.map(&:attributes))
    end

    File.write(
      'tmp/staff_applications.yml',
      {
        'applications' => applications,
        'staff_applications' => staff_applications,
        'tokens' => tokens
      }.to_yaml
    )

    FileUtils.chmod(0o600, 'tmp/staff_applications.yml')
  rescue StandardError
    FileUtils.rm('tmp/staff_applications.yml') if File.exist?('tmp/staff_applications.yml')
  end

  desc 'Loads staff applications from a dump'
  task load_staff_applications: :environment do
    unless File.exist?('tmp/staff_applications.yml')
      puts 'No staff applications dump found'
      exit
    end

    apps = YAML.unsafe_load_file('tmp/staff_applications.yml')

    StaffApplication.transaction do
      StaffApplication.destroy_all

      OAuthApplication.insert_all!(apps['applications']) if apps['applications'].any?
      StaffApplication.insert_all!(apps['staff_applications']) if apps['staff_applications'].any?
      Doorkeeper::AccessToken.insert_all!(apps['tokens']) if apps['tokens'].any?

      FileUtils.rm('tmp/staff_applications.yml')
    rescue StandardError
      puts <<~MESSAGE
        ┌─────────────────────────────────────────────────────────────────────────┐
        │            !!!️  CONNECTING ETMODEL AND TRANSITION PATHS  !!!️            │
        ├─────────────────────────────────────────────────────────────────────────┤
        │ Importing a database dump removed the credentials used to connect your  │
        │ local ETModel or Transition Paths app with ETEngine.                    │
        │                                                                         │
        │ If you wish you connect ETModel or Transition Paths with your local     │
        │ ETEngine:                                                               │
        │                                                                         │
        │ 1. Start ETEngine: bundle exec rails server.                            │
        │ 2. Sign in to your account at http://localhost:3000.                    │
        │ 3. Scroll down and create a new ETModel or Transition Path application. │
        │ 4. Copy the generated config to the other application.                  │
        │ 5. Restart the other application.                                       │
        └─────────────────────────────────────────────────────────────────────────┘
      MESSAGE
    end
  end
end
