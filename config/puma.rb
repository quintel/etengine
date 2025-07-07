# frozen_string_literal: true

require 'etc'

# Puma can serve each request in a thread from an internal thread pool.
#
# The `threads` method setting takes two numbers: a minimum and maximum. Any libraries that use
# thread pools should be configured to match the maximum value specified for Puma. Default is set to
# 5 threads for minimum and maximum; this matches the default thread size of Active Record.
#
# ETEngine is not thread-safe, so we use 1 thread per worker.
threads 1, 1

# 1 worker per CPU
workers Etc.nprocessors

# Preload the app before forking to save memory via Copy-On-Write
preload_app!

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port        ENV.fetch('PORT')    { 3000 }

# Specifies the `environment` that Puma will run in.
environment ENV.fetch('RAILS_ENV'){ 'development' }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }

# Re-establish connections in each worker
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
