namespace :ci do
  ETSOURCE_REPO = 'git@github.com:dennisschoenmakers/etsource.git'

  desc <<-DESC
    Runs tasks to prepare a CI build on Semaphore.

    Adds config.yml, clones a copy of ETsource, installs dependencies, and
    sets up the database.
  DESC

  task :setup do
    # Config.
    if File.exists?('config/config.yml')
      raise 'config/config.yml already exists. Not continuing.'
    end

    original = YAML.load_file('config/config.yml.sample')
    config   = { 'development' => original['ci'], 'test' => original['ci'] }

    File.write('config/config.yml', YAML.dump(config))

    # ETsource.
    sh "git clone --depth 1 #{ ETSOURCE_REPO } tmp/etsource"

    # Bundler.
    sh 'bundle install --deployment --path vendor/bundle'

    # Database.
    Rake::Task['db:setup'].invoke
    Rake::Task['db:test:prepare'].invoke
  end
end
