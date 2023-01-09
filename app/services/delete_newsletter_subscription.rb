# frozen_string_literal: true

class DeleteNewsletterSubscription
  include Dry::Monads[:result]

  def call(user:)
    ETEngine::Mailchimp.client.patch(
      "members/#{ETEngine::Mailchimp.subscriber_id(user.email)}",
      status: 'unsubscribed'
    )

    Success()
  rescue Faraday::ResourceNotFound
    Success()
  rescue Faraday::Error => e
    Failure(e)
  end
end
