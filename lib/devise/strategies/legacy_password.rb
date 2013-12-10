module Devise
  module Strategies
    # Signs in users who haven't signed in since migrating to Devise. This
    # hashes their old SHA512'ed password using BCrypt and compares it with the
    # "old_crypted_password" column. If the password is valid, we migrate them
    # to the Devise BCrypt column.
    #
    # See http://blog.jgc.org/2012/06/one-way-to-fix-your-rubbish-password.html
    class LegacyPassword < Devise::Strategies::Base
      def valid?
        params[:user] && params[:user][:email] &&
          (user = find_resource) && user.old_crypted_password.present?
      end

      def authenticate!
        user         = find_resource
        sha_password = sha_digest(params[:user][:password], user)
        bc_password  = BCrypt::Password.new(user.old_crypted_password)

        if bc_password == sha_password
          # We successfully logged in; remove the old Authlogic-related
          # attributes so that the normal Devise strategies are used next time.
          user.password              = params[:user][:password]
          user.password_confirmation = params[:user][:password]
          user.old_crypted_password  = nil
          user.password_salt         = nil

          user.save(validate: false)

          success!(user)
        end

        fail(:not_found_in_database) unless user
      end

      #######
      private
      #######

      def find_resource
        mapping.to.where(email: params[:user][:email]).first
      end

      def sha_digest(password, user)
        digest = "#{ password }#{ user.password_salt }"
        20.times { digest = Digest::SHA512.hexdigest(digest) }

        digest
      end
    end # LegacyPassword

    Warden::Strategies.add(:legacy_password, Devise::Strategies::LegacyPassword)
  end # Strategies
end # Devise
