module MyEtm
  class Version < ActiveResource::Base
    self.site = "#{Settings.idp_url}/api/v1"

    def self.all_other_versions
      Rails.cache.fetch(:api_versions) do
        find(:all).reject { |v| v.tag == ETEngine::Version::TAG }
      end
    end
  end
end
