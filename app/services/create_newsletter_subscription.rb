# frozen_string_literal: true

class CreateNewsletterSubscription
  include Dry::Monads[:result, :maybe]

  def call(user:)
    case FetchNewsletterSubscriber.new.call(email: user.email)
    in Success(Some({ status: 'pending' | 'subscribed', ** } => subscriber))
      # User is already subscribed. Nothing to do.
      Success(subscriber)
    in Success(Some(subscriber))
      # User is known. Update their status to pending.
      update_subscription(subscriber)
    in Success(None())
      # New user.
      create_subscription(user)
    in Failure(_) => failure
      failure
    end
  rescue Faraday::Error => e
    Failure(e)
  end

  private

  def create_subscription(user)
    Success(
      ETEngine::Mailchimp.client.post('members', {
        email_address: user.email,
        status: 'pending'
      }).body.symbolize_keys
    )
  end

  def update_subscription(subscriber)
    Success(
      ETEngine::Mailchimp.client.patch(
        "members/#{subscriber[:id]}",
        status: 'pending'
      ).body.symbolize_keys
    )
  end
end
