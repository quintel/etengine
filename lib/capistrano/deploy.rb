namespace :deploy do
  task :app_config do
    run "cd #{current_release} && rake deploy:app_config"
    run "ln -sf #{shared_path}/config/database.yml #{release_path}/config/"
  end # setup_config

  desc <<-DESC
    Imports a specific revision of ETSource

    Provide the task with an ETSOURCE_REV environment variable whose value is
    a commit reference from the ETSource repository. This commit will be loaded
    on the server. If you choose not to provide an ETSOURCE_REV variable, the
    revision from the currently-running application will be used.

    See etsource:load rake task'
  DESC
  task :etsource do
    # During a deploy, current_release is the same as latest_release; however
    # when running the task standalone, it is not. Therefore the variable
    # containing the path of the previous ETEngine release differs depending on
    # the context.
    if current_release == release_path
      # This is a deploy.
      old_release = previous_release
    else
      # Not a deploy; running standalone.
      old_release = current_release
    end

    rev = ENV['ETSOURCE_REV'] ||
      capture("cat #{old_release}/tmp/etsource/REVISION")

    run "cd #{current_release} && " \
        "RAILS_ENV=#{rails_env} REV=#{rev.strip} " \
        "rake deploy:load_etsource deploy:calculate_datasets"
  end # load_etsource
end # deploy
