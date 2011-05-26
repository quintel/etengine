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
    run "cp #{config_files}/* #{release_path}/config/"
    run "cd #{release_path}; chmod 777 public/images public/stylesheets tmp"
    run "ln -nfs #{shared_path}/vendor_bundle #{release_path}/vendor/bundle"
    run "cd #{release_path} && bundle install"

    memcached.flush
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