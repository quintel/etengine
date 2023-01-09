# frozen_string_literal: true

RSpec.describe CreateNewsletterSubscription do
  let(:user) { create(:user, email: 'john.doe@example.org') }

  def stub_mailchimp_request(url, method: :get)
    conn = Faraday.new do |builder|
      builder.adapter(:test) do |stub|
        stub.public_send(method, url) do |_env|
          yield
        end
      end
    end

    allow(ETEngine::Mailchimp).to receive(:client).and_return(conn)
  end

  context 'when the subscriber exists with status="unsubscribed"' do
    before do
      stub_mailchimp_request('members/a4bf5bbb9feaa2713d99a3b52ab80024', method: :patch) do
        [
          200,
          { 'Content-Type' => 'application/json' },
          {}
        ]
      end

      allow(ETEngine::Mailchimp)
        .to receive(:fetch_subscriber)
        .and_return({ 'status' => 'unsubscribed', 'id' => 'a4bf5bbb9feaa2713d99a3b52ab80024' })
    end

    it 'returns a success' do
      expect(described_class.new.call(user:)).to be_success
    end
  end

  context 'when the subscriber exists with status="pending"' do
    before do
      allow(ETEngine::Mailchimp)
        .to receive(:fetch_subscriber)
        .and_return({ 'status' => 'pending', 'id' => 'a4bf5bbb9feaa2713d99a3b52ab80024' })
    end

    it 'returns a success' do
      expect(described_class.new.call(user:)).to be_success
    end
  end

  context 'when the subscriber exists with status="subscribed"' do
    before do
      allow(ETEngine::Mailchimp)
        .to receive(:fetch_subscriber)
        .and_return({ 'status' => 'subscribed', 'id' => 'a4bf5bbb9feaa2713d99a3b52ab80024' })
    end

    it 'returns a success' do
      expect(described_class.new.call(user:)).to be_success
    end
  end

  context 'when the subscriber does not exist' do
    before do
      stub_mailchimp_request('members', method: :post) do
        [
          200,
          { 'Content-Type' => 'application/json' },
          {}
        ]
      end

      allow(ETEngine::Mailchimp)
        .to receive(:fetch_subscriber)
        .and_raise(Faraday::ResourceNotFound)
    end

    it 'returns a success' do
      expect(described_class.new.call(user:)).to be_success
    end
  end

  context 'when an error occurs' do
    before do
      stub_mailchimp_request('members/a4bf5bbb9feaa2713d99a3b52ab80024', method: :patch) do
        raise Faraday::ClientError
      end

      allow(ETEngine::Mailchimp)
        .to receive(:fetch_subscriber)
        .and_return({ 'status' => 'unsubscribed', 'id' => 'a4bf5bbb9feaa2713d99a3b52ab80024' })
    end

    it 'returns a failure' do
      expect(described_class.new.call(user:)).to be_failure
    end
  end

  context 'when fetching the user fails' do
    before do
      allow(ETEngine::Mailchimp)
        .to receive(:fetch_subscriber)
        .and_raise(Faraday::ClientError)
    end

    it 'returns a failure' do
      expect(described_class.new.call(user:)).to be_failure
    end
  end
end
