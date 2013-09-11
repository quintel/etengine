# Sets up the necessary stubs to use the fixture version of ETsource located
# at spec/fixtures/etsource.
module ETSourceFixtureHelper
  # A custom Atlas loader which will not attempt to calculate the dataset in
  # Atlas and Refinery. It also uses YAML (since it is easier for humans to
  # edit), instead of MessagePack.
  class AtlasTestLoader < Etsource::AtlasLoader::PreCalculated
    def calculate!(*)
      # noop
    end

    def reload!(*)
      # noop
    end

    #######
    private
    #######

    def parse(data)
      YAML.load(data)
    end

    def dump(data)
      YAML.dump(data)
    end

    def data_path(dataset_key)
      super.dirname.join("#{ dataset_key }.yml")
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
