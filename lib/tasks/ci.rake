namespace :ci do
  desc <<-DESC
    Runs tasks to prepare a CI build on Semaphore.
  DESC

  task :setup do
    # Config.
    if File.exists?('config/config.yml')
      raise 'config/config.yml already exists. Not continuing.'
    end

    original = YAML.load_file('config/config.yml.sample')
    config   = { 'development' => original['ci'], 'test' => original['ci'] }

    File.write('config/config.yml', YAML.dump(config))
  end
end
