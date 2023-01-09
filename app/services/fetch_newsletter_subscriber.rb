# frozen_string_literal: true

class FetchNewsletterSubscriber
  include Dry::Monads[:result, :maybe]

  def call(email:)
    Success(Some(ETEngine::Mailchimp.fetch_subscriber(email).symbolize_keys))
  rescue Faraday::ResourceNotFound
    Success(None())
  rescue Faraday::Error => e
    Failure(e)
  end
end
