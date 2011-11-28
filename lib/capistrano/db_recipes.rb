namespace :db do
  desc "Move production db to staging db, overwriting everything"
  task :prod2staging_all do    
    warning("You know what you're doing, right? You will overwrite the entire staging db!")
    production
    file = dump_db_to_tmp
    staging
    db.empty
    load_sql_into_db(file)
  end
  
  desc "Copy users, and scenarios from production to staging with the exception of protected and preset scenarios"
  task :prod2staging_safe_tables do
    warning "users and (partially) scenarios tables on staging will be overwritten with production data"
    production
    tables = %w{users}
    file = dump_db_to_tmp(tables)
    staging
    load_sql_into_db(file)
      
    puts "Now let's make a dump of the scenarios we don't need"
    production
    file = dump_db_to_tmp(['scenarios'], "--where='in_start_page != 1 AND protected != 1' --skip-add-drop-table")
    staging
    run_mysql_query "DELETE FROM scenarios WHERE in_start_page != 1 AND protected != 1"
    load_sql_into_db(file)
  end  

  desc "Move staging db to production db, overwriting everything"
  task :staging2prod_all do    
    warning("You know what you're doing, right? You will overwrite the entire production db!")
    staging
    file = dump_db_to_tmp
    production
    db.empty
    load_sql_into_db(file)
  end
  
  desc "Empty db - be sure you know what you're doing"
  task :empty do
    warning("You know what you're doing, right? This will drop #{db_name}")    
    dump_db_to_tmp
    run "mysqladmin drop #{db_name}"
    run "mysqladmin create #{db_name} -u #{db_user} --password=#{db_pass}"
  end
  
  desc "If you've unintenionally ran db:empty"
  task :oops do
    puts "Shame on you!"
    file = "/tmp/#{db_name}.sql"
    run "mysql -u #{db_user} --password=#{db_pass} --host=#{db_host} #{db_name} < #{file}"
  end
end

desc "Move db server to local db"
task :db2local do
  file = dump_db_to_tmp
  puts "Gzipping sql file"
    run "gzip -f #{file}"
  puts "Downloading gzip file"
    get file + ".gz", "#{db_name}.sql.gz"
  puts "Gunzip gzip file"
    system "gunzip -f #{db_name}.sql.gz"
  puts "Importing sql file to db"
    system "mysqladmin -f -u root drop #{local_db_name}"
    system "mysqladmin -u root create #{local_db_name}"
    system "mysql -u root #{local_db_name} < #{db_name}.sql"
end

# Helper methods

# dumps the entire db to the tmp folder and returns the full filename
# the optional tables parameter should be an array of string
def dump_db_to_tmp(tables = [], options = nil)
  file = "/tmp/#{db_name}.sql"
  puts "Exporting #{db_name} to sql file, filename: #{file}"
  run "mysqldump -u #{db_user} --password=#{db_pass} --host=#{db_host} #{db_name} #{tables.join(' ')} #{options} > #{file}"
  file
end

# watchout! this works on remote boxes, not on the developer box
def load_sql_into_db(file)
  puts "Importing sql file to #{db_name}"
  run "mysql -u #{db_user} --password=#{db_pass} --host=#{db_host} #{db_name} < #{file}"
end

def warning(msg)
  puts "Warning! These tasks have destructive effects."
  unless Capistrano::CLI.ui.agree(msg)
    puts "Wise man"; exit
  end
end

def run_mysql_query(q)
  run "mysql -u #{db_user} --password=#{db_pass} --host=#{db_host} #{db_name} -e '#{q}'"
end
