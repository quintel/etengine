# Sets up the necessary stubs to use the fixture version of ETsource located
# at spec/fixtures/etsource.
module ETSourceFixtureHelper
  def self.included(config)
    config.around do |example|
      fixture_path = Rails.root.join('spec/fixtures/etsource/data')

      NastyCache.instance.expire!
      ETSource.with_data_dir(fixture_path) { example.run }
    end
  end
end # EtmFixtureHelper
