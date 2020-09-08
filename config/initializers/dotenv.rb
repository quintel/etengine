# frozen_string_literal: true

unless ENV.key?('RAILS_SECRET_KEY_BASE')
  require 'dotenv'
  Dotenv.load('.env')
end
