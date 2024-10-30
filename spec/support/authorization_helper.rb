# # frozen_string_literal: true

# module AuthorizationHelper
#   def access_token_header(user, scopes, expires_in: 1.hour)
#     scopes =
#       case scopes
#       when :public
#         'public'
#       when :read
#         'public scenarios:read'
#       when :write
#         'public scenarios:read scenarios:write'
#       when :delete
#         'public scenarios:read scenarios:write scenarios:delete'
#       else
#         if scopes.is_a?(Symbol)
#           raise "Unknown scope alias #{scopes.inspect}, expected :public, :read, :write, " \
#                 ':delete or a string'
#         end

#         scopes.to_s
#       end

#     token = create(:access_token, resource_owner_id: user.id, scopes: scopes.to_s, expires_in: expires_in.to_i)
#     { 'Authorization' => "Bearer #{token.access_token}" }
#   end

#   def stub_faraday_422(body)
#     faraday_response = instance_double(Faraday::Response)
#     allow(faraday_response).to receive(:[]).with(:body).and_return('errors' => body)

#     Faraday::UnprocessableEntityError.new(nil, faraday_response)
#   end
# end


module AuthorizationHelper
  def access_token_header(user, scopes, expires_in: 1.hour)
    scopes = normalize_scopes(scopes)

    # Create an access token with the necessary attributes
    token = create(:access_token, resource_owner_id: user.id, scopes: scopes.to_s, expires_in: expires_in.to_i)

    # Prepare mock token with `sub` and `scopes` if needed
    mock_token = OpenStruct.new(sub: user.id.to_s, scopes: scopes)

    # Only mock the token decoder if the test supports it
    if defined?(ETEngine::TokenDecoder)
      allow(ETEngine::TokenDecoder).to receive(:decode).and_return(mock_token)
    end

    { 'Authorization' => "Bearer #{token.token}" }
  end

  private

  def normalize_scopes(scopes)
    case scopes
    when :public
      'public'
    when :read
      'public scenarios:read'
    when :write
      'public scenarios:read scenarios:write'
    when :delete
      'public scenarios:read scenarios:write scenarios:delete'
    else
      if scopes.is_a?(Symbol)
        raise "Unknown scope alias #{scopes.inspect}, expected :public, :read, :write, :delete or a string"
      end
      scopes.to_s
    end
  end

  def stub_faraday_422(body)
    faraday_response = instance_double(Faraday::Response)
    allow(faraday_response).to receive(:[]).with(:body).and_return('errors' => body)
    Faraday::UnprocessableEntityError.new(nil, faraday_response)
  end
end
