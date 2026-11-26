# frozen_string_literal: true

# Access to a user sortable is determined solely by the token's scenario_access grant. Expects the
# including spec to define `scenario` (bound, so the grant is the only route to access), `url`,
# `user` and `valid_options`.
RSpec.shared_examples_for 'a user sortable with grant-based access' do |model|
  def sortable_headers(scopes = :write, write: [], read: [])
    access_token_header(user, scopes, scenario_access: scenario_grant(write:, read:))
  end

  describe 'access' do
    let(:fetch) { get(url, headers:) }
    let(:update) { put(url, params: { order: valid_options.reverse }, headers:) }

    shared_examples_for 'a readable sortable' do
      it 'allows fetching the order' do
        fetch
        expect(response).to have_http_status(:ok)
      end
    end

    shared_examples_for 'an unreadable sortable' do
      it 'refuses fetching the order' do
        fetch
        expect(response).to have_http_status(:not_found)
      end
    end

    shared_examples_for 'an updatable sortable' do
      it 'allows updating the order' do
        update
        expect(response).to have_http_status(:ok)
      end

      it 'saves the order' do
        expect { update }.to change(model, :count).by(1)
      end
    end

    shared_examples_for 'a non-updatable sortable' do |status|
      it "refuses updating the order with #{status}" do
        update
        expect(response).to have_http_status(status)
      end

      it 'does not save the order' do
        expect { update }.not_to change(model, :count)
      end
    end

    context 'when the scenario is public' do
      context 'when the token has no grant for the scenario' do
        let(:headers) { sortable_headers }

        it_behaves_like 'a readable sortable'
        it_behaves_like 'a non-updatable sortable', :forbidden
      end

      context 'when the token grants read access (viewer)' do
        let(:headers) { sortable_headers(read: [scenario.id]) }

        it_behaves_like 'a readable sortable'
        it_behaves_like 'a non-updatable sortable', :forbidden
      end

      context 'when the token grants write access' do
        let(:headers) { sortable_headers(write: [scenario.id]) }

        it_behaves_like 'a readable sortable'
        it_behaves_like 'an updatable sortable'
      end

      context 'when the token grants write access without the scenarios:write scope' do
        let(:headers) { sortable_headers(:read, write: [scenario.id]) }

        it_behaves_like 'a readable sortable'
        it_behaves_like 'a non-updatable sortable', :forbidden
      end
    end

    context 'when the scenario is private' do
      before { scenario.update!(private: true) }

      context 'when the token has no grant for the scenario' do
        let(:headers) { sortable_headers }

        it_behaves_like 'an unreadable sortable'
        it_behaves_like 'a non-updatable sortable', :not_found
      end

      context 'when the token grants read access (viewer)' do
        let(:headers) { sortable_headers(read: [scenario.id]) }

        it_behaves_like 'a readable sortable'
        it_behaves_like 'a non-updatable sortable', :not_found
      end

      context 'when the token grants write access' do
        let(:headers) { sortable_headers(write: [scenario.id]) }

        it_behaves_like 'a readable sortable'
        it_behaves_like 'an updatable sortable'
      end
    end
  end
end
