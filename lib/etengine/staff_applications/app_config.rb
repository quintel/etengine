# frozen_string_literal: true

module ETEngine
  module StaffApplications
    # Defines an OAuth application which will be created for staff users.
    class AppConfig < Dry::Struct
      attribute  :key,             Dry::Types['strict.string']
      attribute  :name,            Dry::Types['strict.string']
      attribute? :redirect_uri,    Dry::Types['strict.string']
      attribute  :confidential,    Dry::Types['strict.bool'].default(true)
      attribute  :scopes,          Dry::Types['strict.string'].default('public')

      attribute  :config_path,     Dry::Types['strict.string']
      attribute? :config_prologue, Dry::Types['strict.string']
      attribute  :config_content,  Dry::Types['strict.string']
      attribute? :config_epilogue, Dry::Types['strict.string']

      # Creates an attribute hash for the OAuth application.
      def to_model_attributes
        { name:, redirect_uri:, confidential:, scopes: }
      end
    end
  end
end
