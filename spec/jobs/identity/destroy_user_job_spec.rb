# frozen_string_literal: true

RSpec.describe Identity::DestroyUserJob, type: :job do
  context 'when Settings.etmodel_uri is set' do
    let(:user) { create(:user) }
    let(:connection) { instance_double(Faraday::Connection) }

    before do
      Settings.etmodel_uri = 'http://example.org'

      allow(ETEngine::Auth)
        .to receive(:etmodel_client)
        .with(user)
        .and_return(connection)

      allow(connection).to receive(:delete)
    end

    after do
      Settings.reload!
    end

    it 'sends a PUT request to the ETModel API' do
      described_class.perform_now(user.id)
      expect(connection).to have_received(:delete).with('/api/v1/user')
    end

    it 'destroys the user' do
      expect { described_class.perform_now(user.id) }
        .to change { User.where(id: user.id).count }.by(-1)
    end

    it 'returns true' do
      expect(described_class.perform_now(user.id)).to be(true)
    end
  end
end
