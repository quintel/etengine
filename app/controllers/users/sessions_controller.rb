# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def create
      super do
        if resource.legacy_password_salt
          migrate_legacy_password(resource, params.require(:user).require(:password))
        end
      end
    end

    private

    # Migrate a user to the new password hashing scheme.
    def migrate_legacy_password(resource, password)
      resource.update_with_password(
        password:,
        legacy_password_salt: nil,
        current_password: password
      )

      bypass_sign_in(resource)
    end
  end
end
