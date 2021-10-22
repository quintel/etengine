namespace :deploy do
  task :app_config do
    on roles(:app) do
      within(release_path) { execute :rake, 'deploy:app_config' }
    end
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
    on roles(:app) do
      # During a deploy, current_release is the same as latest_release; however
      # when running the task standalone, it is not. Therefore the variable
      # containing the path of the previous ETEngine release differs depending
      # on the context.
      # if current_path == release_path
        # # Not a deploy; running standalone.
        # this_release = old_release = current_release
      # else
        # # This is a deploy.
        # old_release  = previous_release
        # this_release = release_path
      # end

      rev =
        if ENV['ETSOURCE_REV']
          ENV['ETSOURCE_REV']
        else
          begin
            within(deploy_path.join('shared/etsource')) { capture('git rev-parse HEAD') }
          rescue
            raise <<-MESSAGE.gsub(/^\s+/, '')
              Unknown existing ETSource version, and no ETSOURCE_REV was provided.
              If this is a cold deploy, be sure to tell ETEngine which version of
              ETSource to use by supplying the ETSOURCE_REV.

              ETSOURCE_REV=some_commit_id cap deploy
            MESSAGE
          end
        end

      within release_path do
        with etsource_ref: rev.strip, rails_env: fetch(:rails_env) do
          execute :rake, 'deploy:load_etsource deploy:calculate_datasets'
        end
      end
    end
  end
end
