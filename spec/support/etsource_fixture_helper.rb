module EtmFixtureHelper
  def self.included(base)
    install_around_hook!(base.config)
    install_before_book!(base.config)
  end

  def self.install_around_hook!(config)
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
  end

  def self.install_before_hook!(config)
    ETSource.stub!(:root).and_return(
      Rails.root.join('spec/fixtures/etsource'))
  end
end # EtmFixtureHelper
