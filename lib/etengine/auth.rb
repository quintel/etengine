# frozen_string_literal: true

module ETEngine
  # Contains useful methods for authentication.
  module Auth
    # Generates a new signing key for use in development and saves it to the tmp directory. If a key
    # already exists there, it will be read.
    def self.openid_signing_key
      return ENV['OPENID_SIGNING_KEY'] if ENV['OPENID_SIGNING_KEY'].present?

      key_path = Rails.root.join('tmp/openid.key')

      return key_path.read if key_path.exist?

      unless Rails.env.test? || Rails.env.development? || ENV['CI']
        raise 'No signing key is present. Please set the OPENID_SIGNING_KEY environment ' \
              'variable or add the key to tmp/openid.key.'
      end

      key = OpenSSL::PKey::RSA.new(2048).to_pem

      unless ENV['CI']
        key_path.write(key)
        key_path.chmod(0o600)
      end

      key
    end
  end
end
