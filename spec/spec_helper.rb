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
require 'shoulda/matchers'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

ActiveRecord::Migration.maintain_test_schema!

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

  config.infer_spec_type_from_file_location!

  config.include(Devise::Test::ControllerHelpers, type: :controller)
  config.include(MechanicalTurkHelper)

  config.include(HouseholdCurvesHelper, household_curves: true)

  # Prevent the static YML file from being deleted.
  config.before(:suite) do
    loader = ETSourceFixtureHelper::AtlasTestLoader.new(
      Rails.root.join('spec/fixtures/etsource/static'))

    Etsource::Dataset::Import.loader = loader

    fixture_path = Rails.root.join('spec/fixtures/etsource')

    Etsource::Base.loader(fixture_path.to_s)
    Atlas.data_dir = fixture_path
  end

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec

    # Choose one or more libraries:
    with.library :rails
  end
end
