# Sets up the necessary stubs to use the fixture version of ETsource located
# at spec/fixtures/etsource.
module ETSourceFixtureHelper
  # A custom Atlas loader which will not attempt to calculate the dataset in
  # Atlas and Refinery.
  class AtlasTestLoader < Etsource::AtlasLoader::PreCalculated
    def calculate!(*)
      # noop
    end

    def reload!(*)
      # noop
    end
  end

  def self.included(config)
    config.around do |example|
      fixture_path = Rails.root.join('spec/fixtures/etsource')

      # Legacy YAML files.
      Etsource::Base.loader(fixture_path.to_s)

      NastyCache.instance.expire!
      Atlas.with_data_dir(fixture_path.join('data')) { example.run }
    end
  end
end # EtmFixtureHelper
