ENV['ETSOURCE_DIR'] ||= 'spec/fixtures/etsource'

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_group "ETsource", "app/models/etsource"
    add_group "Qernel", "app/models/qernel"
    add_group "GQL", "app/models/gql"
    #add_group "Controllers", "app/controllers"
  end
end

require 'rubygems'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun' # Required for Rcov to run.

require 'webrat'
require 'authlogic/test_case'
require 'factory_girl'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # Tries to find examples / groups with the focus tag, and runs them. If no
  # examples are focues, run everything. Prevents the need to specify
  # `--tag focus` when you only want to run certain examples.
  # config.filter_run(push_relabel: true)
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # Allow adding examples to a filter group with only a symbol.
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.include(Webrat::Matchers)
  config.include(Authlogic::TestCase)
  config.include(EtmAuthHelper)
  config.include(MechanicalTurkHelper)
  config.include(ETSourceFixtureHelper)

  # Prevent the static YML file from being deleted.
  config.before(:suite) do
    loader = ETSourceFixtureHelper::AtlasTestLoader.new(
      Rails.root.join('spec/fixtures/etsource/static'))

    Etsource::Dataset::Import.loader = loader
  end
end
