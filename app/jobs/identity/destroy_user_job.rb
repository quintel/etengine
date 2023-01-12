# frozen_string_literal: true

# Permanently deletes a user.
class Identity::DestroyUserJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    ETEngine::Auth.etmodel_client(user).delete('/api/v1/user') if Settings.etmodel_uri

    # Personal access tokens must be deleted before the access tokens, otherwise the destory will
    # fail due to a foreign key constraint.
    user.personal_access_tokens.delete_all
    user.destroy

    true
  end
end
