# frozen_string_literal: true

module ETEngine
  module StaffApplications
    # Defines an OAuth application which will be created for staff users.
    class AppConfig < Dry::Struct
      attribute  :key,             Dry::Types['strict.string']
      attribute  :name,            Dry::Types['strict.string']
      attribute  :uri,             Dry::Types['strict.string']
      attribute? :redirect_path,   Dry::Types['strict.string']
      attribute  :confidential,    Dry::Types['strict.bool'].default(true)
      attribute  :scopes,          Dry::Types['strict.string'].default('public')
      attribute? :run_command,     Dry::Types['strict.string']

      attribute  :config_path,     Dry::Types['strict.string']
      attribute? :config_prologue, Dry::Types['strict.string']
      attribute  :config_content,  Dry::Types['strict.string']
      attribute? :config_epilogue, Dry::Types['strict.string']

      # Creates an attribute hash for the OAuth application.
      def to_model_attributes
        redirect_uri = URI.parse(uri)
        redirect_uri.path = redirect_path

        { name:, uri:, redirect_uri: redirect_uri.to_s, confidential:, scopes: }
      end
    end
  end
end
