# frozen_string_literal: true

class CreateNewsletterSubscription
  include Dry::Monads[:result]

  def call(user:)
    subscriber = ETEngine::Mailchimp.fetch_subscriber(user.email)

    if %w[pending subscribed].include?(subscriber['status'])
      # User is already subscribed.
      Success(subscriber)
    else
      update_subscription(subscriber)
    end
  rescue Faraday::ResourceNotFound
    create_subscription(user)
  rescue Faraday::Error => e
    Failure(e)
  end

  private

  def create_subscription(user)
    Success(
      ETEngine::Mailchimp.client.post('members', {
        email_address: user.email,
        status: 'pending'
      }).body
    )
  end

  def update_subscription(subscriber)
    Success(
      ETEngine::Mailchimp.client.patch(
        "members/#{subscriber['id']}",
        status: 'pending'
      ).body
    )
  end
end
