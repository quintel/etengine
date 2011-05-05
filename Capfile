load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks

namespace :memcached do 
  desc "Start memcached"
  task :start, :roles => [:app] do
    run "/etc/init.d/memcached start"
  end

  desc "Stop memcached"
  task :stop, :roles => [:app] do
    run "/etc/init.d/memcached stop"
  end

  desc "Restart memcached"
  task :restart, :roles => [:app] do
    run "/etc/init.d/memcached restart"
  end        

  desc "Flush memcached - this assumes memcached is on port 11211"
  task :flush, :roles => [:app] do
    run "echo 'flush_all' | nc -q 1 localhost 11211"
  end     
end


namespace :deploy do
  task :after_update_code do
    run "cp #{config_files}/database.yml #{release_path}/config/database.yml"
    run "cp #{config_files}/server_variables.rb #{release_path}/config/server_variables.rb"
    run "cp #{config_files}/hoptoad.rb #{release_path}/config/initializers/hoptoad.rb"
    run "cd #{release_path}; ls -lh public"
    run "cd #{release_path}; chmod 777 public/images public/stylesheets tmp"
    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
    run "ln -nfs #{shared_path}/assets/pdf #{release_path}/public/pdf"
    run "ln -nfs #{shared_path}/vendor_bundle #{release_path}/vendor/bundle"
    run "cd #{release_path} && bundle install"

    #deploy.generate_rdoc
    memcached.flush
  end

  desc 'Import seeds on server'
  task :seed, :roles => [:db] do
    run "cd #{deploy_to}/current; rake db:seed RAILS_ENV=#{stage}"
  end

  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :after_deploy do
    deploy.cleanup
  end

end

desc "Move db server to local db"
task :db2local do
  puts "Exporting db to sql file"
  file = "/root/tmp/etm_#{server_type}.sql"
  run "mysqldump -u root --password=quintel etm_#{server_type} > #{file}"
  puts "Gzipping sql file"
  run "gzip -f #{file}"
  puts "Downloading gzip file"
  get file+".gz", "etm_#{server_type}.sql.gz" 
  puts "Gunzip gzip file"
  system "gunzip -f etm_#{server_type}.sql.gz"
  puts "Importing sql file to db"
  system "mysql -u root etm_dev < etm_#{server_type}.sql"
end


%w[staging testing prod].each do |stage|
  desc "Move #{stage} db to local db"
  task "#{stage}2local" do
    self.send(stage)
    db2local
  end
end