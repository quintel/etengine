# frozen_string_literal: true

require 'spec_helper'

describe 'Updating a scenario with API v3' do
  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) do
    FactoryBot.create(:scenario)
  end

  def update_scenario(params: {}, headers: {})
    put("/api/v3/scenarios/#{scenario.id}", params:, headers:)
    scenario.reload
  end

  context 'with a keep-compatible scenario' do
    let(:user) { create(:user) }
    let(:headers) { access_token_header(user, :write) }

    before do
      scenario.update!(keep_compatible: true)
    end

    context 'when setting keep_compatible to false' do
      let(:params) { { scenario: { keep_compatible: false } } }

      it 'sets keep_compatible to false' do
        expect {
          patch api_v3_scenario_path(scenario.id), params: params, headers: headers
        }.to change { scenario.reload.keep_compatible? }
          .from(true).to(false)
      end
    end
  end

  context 'when setting the scenario keep_compatible to true' do
    let(:params) { { scenario: { keep_compatible: true } } }
    let(:user) { create(:user) }
    let(:headers) { access_token_header(user, :write) }

    it 'sets keep_compatible to true' do
      expect { update_scenario(params:, headers:) }
        .to change(scenario, :keep_compatible?).from(false).to(true)
    end
  end

  context 'when setting the scenario to be private as a guest' do
    let(:params) { { scenario: { private: true } } }

    it 'does not change the scenario privacy' do
      expect { update_scenario(params:) }
        .not_to change(scenario, :private?).from(false)
    end
  end

  context 'when setting an owned public scenario to be private' do
    before do
      scenario.delete_all_users
      scenario.update!(user: user, private: false)
    end

    let(:user) { create(:user) }

    it 'sets private to true' do
      expect do
        update_scenario(
          params: { scenario: { private: true } },
          headers: access_token_header(user, :write)
        )
      end.to change(scenario, :private?).from(false).to(true)
    end
  end

  context 'when setting an owned private scenario to be public' do
    before do
      scenario.delete_all_users
      scenario.update(user: user)
      scenario.reload.update(private: true)
    end

    let(:user) { create(:user) }

    it 'sets private to false' do
      expect do
        update_scenario(
          params: { scenario: { private: false } },
          headers: access_token_header(user, :write)
        )
      end.to change(scenario, :private?).from(true).to(false)
    end
  end

  context 'when the owner binds a scenario' do
    let(:params) { { scenario: { bound: true } } }
    let(:user) { create(:user) }
    let(:headers) { access_token_header(user, :delete) }

    before { scenario.update!(user:) }

    it 'sets bound to true' do
      expect { update_scenario(params:, headers:) }
        .to change(scenario, :bound?).from(false).to(true)
    end
  end

  context 'when the owner unbinds a scenario' do
    let(:params) { { scenario: { bound: false } } }
    let(:user) { create(:user) }
    let(:headers) { access_token_header(user, :delete) }

    before { scenario.update!(user:, bound: true) }

    it 'sets bound to false' do
      expect { update_scenario(params:, headers:) }
        .to change(scenario, :bound?).from(true).to(false)
    end
  end

  context 'when the owner binds an already bound scenario' do
    let(:params) { { scenario: { bound: true } } }
    let(:user) { create(:user) }
    let(:headers) { access_token_header(user, :delete) }

    before { scenario.update!(user:, bound: true) }

    it 'does not change the scenario binding' do
      expect { update_scenario(params:, headers:) }
        .not_to change(scenario, :bound?).from(true)
    end

    it 'is successful' do
      update_scenario(params:, headers:)

      expect(response.status).to eql(200)
    end
  end

  context 'when the owner binds with only the write scope' do
    let(:params) { { scenario: { bound: true } } }
    let(:user) { create(:user) }
    let(:headers) { access_token_header(user, :write) }

    before { scenario.update!(user:) }

    it 'does not change the scenario binding' do
      expect { update_scenario(params:, headers:) }
        .not_to change(scenario, :bound?).from(false)
    end
  end

  context 'when a collaborator binds a scenario' do
    let(:params) { { scenario: { bound: true } } }
    let(:collaborator) { create(:user) }
    let(:headers) { access_token_header(collaborator, :delete) }

    before do
      scenario.update!(user: create(:user))

      create(
        :scenario_user,
        scenario:,
        user: collaborator,
        role_id: User::ROLES.key(:scenario_collaborator)
      )
    end

    it 'does not change the scenario binding' do
      expect { update_scenario(params:, headers:) }
        .not_to change(scenario, :bound?).from(false)
    end
  end

  context 'when binding an unowned scenario as a guest' do
    let(:params) { { scenario: { bound: true } } }

    it 'does not change the scenario binding' do
      expect { update_scenario(params:) }
        .not_to change(scenario, :bound?).from(false)
    end

    it 'returns a 403' do
      update_scenario(params:)

      expect(response.status).to eq(403)
    end
  end

  context 'when a scenario has a version tag set by another user' do
    let(:params) { { scenario: { private: true } } }
    let(:user) { create(:user) }

    before do
      scenario.delete_all_users
      scenario.update(user: user)

      second_user = create(:user)
      create(:scenario_user, user: second_user, scenario: scenario, role_id: 2)

      scenario.scenario_version_tag = create(
        :scenario_version_tag,
        scenario: scenario,
        user: second_user
      )

      scenario.reload
    end

    it 'changes the version tag user to the user that last updated the scenario' do
      update_scenario(params:, headers: access_token_header(user, :delete))
      scenario.scenario_version_tag.reload

      expect(scenario.scenario_version_tag.user.id).to eq(user.id)
    end
  end

  context 'with update webhooks configured' do
    ActiveJob::Base.queue_adapter = :test
    let(:user) { create(:user) }

    context 'when user values were updated' do
      let(:params) { { scenario: { user_values: { bool: 0.0 } } } }

      it 'collections session invalidation was triggered' do
        expect { update_scenario(params:, headers: access_token_header(user, :delete)) }.to(
          have_enqueued_job(InvalidateCollectionSessionJob)
        )
      end
    end

    context 'when user values were not updated' do
      let(:params) { { scenario: { private: true } } }

      it 'collections session invalidation was triggered' do
        expect { update_scenario(params:, headers: access_token_header(user, :delete)) }.not_to(
          have_enqueued_job(InvalidateCollectionSessionJob)
        )
      end
    end
  end
end
