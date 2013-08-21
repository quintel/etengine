# Sets up the necessary stubs to use the fixture version of ETsource located
# at spec/fixtures/etsource.
module ETSourceFixtureHelper
  def self.included(config)
    config.around do |example|
      fixture_path = Rails.root.join('spec/fixtures/etsource/data')
      Etsource::Base.loader('spec/fixtures/etsource')

      NastyCache.instance.expire!
      Atlas.with_data_dir(fixture_path) { example.run }
    end

    config.before(:each) do
      stub_const(
        'Etsource::Dataset::Import::STATIC_REGION_FILES',
        Rails.root.join('spec/fixtures/etsource'))
    end
  end
end # EtmFixtureHelper
