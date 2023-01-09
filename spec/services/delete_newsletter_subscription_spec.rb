# frozen_string_literal: true

RSpec.describe DeleteNewsletterSubscription do
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

  context 'when the request succeeds' do
    before do
      stub_mailchimp_request('members/a4bf5bbb9feaa2713d99a3b52ab80024', method: :patch) do
        [
          200,
          { 'Content-Type' => 'application/json' },
          {}
        ]
      end
    end

    it 'returns a success' do
      expect(described_class.new.call(user:)).to be_success
    end
  end

  context 'when the subscriber does not exist' do
    before do
      stub_mailchimp_request('members/a4bf5bbb9feaa2713d99a3b52ab80024', method: :patch) do
        raise Faraday::ResourceNotFound
      end
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
    end

    it 'returns a failure' do
      expect(described_class.new.call(user:)).to be_failure
    end
  end
end
