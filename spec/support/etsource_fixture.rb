# Sets up the necessary stubs to use the fixture version of ETsource located
# at spec/fixtures/etsource.
module ETSourceFixtureHelper
  def self.included(config)
    config.around do |example|
      base            = Etsource::Base.instance
      new_path        = Rails.root.join('spec/fixtures/etsource')
      orig_base_dir   = base.base_dir
      orig_export_dir = base.export_dir

      begin
        NastyCache.instance.expire!

        base.base_dir   = new_path
        base.export_dir = new_path

        example.run
      ensure
        base.base_dir   = orig_base_dir
        base.export_dir = orig_export_dir
      end
    end

    config.before do
      ETSource.stub!(:root).and_return(
        Rails.root.join('spec/fixtures/etsource'))
    end
  end
end # EtmFixtureHelper
