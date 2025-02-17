# frozen_string_literal: true

module MyEtm
  class Version < ActiveResource::Base
    self.site = "#{Settings.identity.issuer}/api/v1"

    def self.all_other_versions
      Rails.cache.fetch(:api_versions) do
        find(:all).reject { |v| v.tag == Settings.version_tag }
      end
    end
  end
end
