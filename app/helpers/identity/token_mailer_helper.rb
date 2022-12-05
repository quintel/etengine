# frozen_string_literal: true

module Identity
  module TokenMailerHelper
    def token_permissions(token)
      permissions = [
        ['View your public scenarios', 'public'],
        ["View other people's public scenarios", 'public'],
        ['View your private scenarios', 'scenarios:read'],
        ['Create new scenarios and change your public and private scenarios', 'scenarios:write'],
        ['Delete your public and private scenarios', 'scenarios:delete']
      ]

      permissions
        .select { |_, scope| token.scopes.include?(scope) }
        .map { |permission, _| "- #{permission}" }
        .join("\n")
    end
  end
end
