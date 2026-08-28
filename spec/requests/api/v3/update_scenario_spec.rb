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

  context 'when updating a share group' do
    let(:user) { create(:user) }
    let(:headers) { access_token_header(user, :write) }
    let(:scenario) { FactoryBot.create(:scenario, user:) }

    let(:group_keys) do
      %w[
        grouped_input_one grouped_input_two grouped_input_three
        grouped_input_four grouped_input_five grouped_input_six
        grouped_input_seven
      ]
    end


    let(:drifting_values) do
      {
        'grouped_input_one' => '53.28',
        'grouped_input_two' => '34.09',
        'grouped_input_three' => '12.6300000001',
        'grouped_input_four' => '0.0',
        'grouped_input_five' => '0.0',
        'grouped_input_six' => '0.0',
        'grouped_input_seven' => '0.0'
      }
    end

    def stored_group_sum
      combined = scenario.user_values.merge(scenario.balanced_values || {})
      combined.slice(*group_keys).values.sum
    end

    context 'with a fully-provided group drifting within the intent tolerance' do
      let(:params) { { scenario: { user_values: drifting_values } } }

      it 'accepts the update' do
        update_scenario(params:, headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'stores the group summing to 100' do
        update_scenario(params:, headers:)
        expect(stored_group_sum).to be_within(1.0e-12).of(100.0)
      end

      it 'keeps zero shares at exactly zero' do
        update_scenario(params:, headers:)

        %w[grouped_input_four grouped_input_five grouped_input_six grouped_input_seven]
          .each do |key|
            expect(scenario.user_values[key]).to eq(0.0)
          end
      end

      it 'preserves the ratios between the shares' do
        update_scenario(params:, headers:)

        expect(scenario.user_values['grouped_input_one'] / scenario.user_values['grouped_input_two'])
          .to be_within(1.0e-12).of(53.28 / 34.09)
      end

      it 'changes each value by less than the smallest expressible step' do
        update_scenario(params:, headers:)
        expect(scenario.user_values['grouped_input_one']).to be_within(1.0e-8).of(53.28)
      end

      it 'logs the repair once, carrying the deviation' do
        allow(Rails.logger).to receive(:info).and_call_original
        update_scenario(params:, headers:)

        expect(Rails.logger).to have_received(:info)
          .with(/Repaired share-group drift: scenario=#{scenario.id} .*deviation=1\.0e-10/)
          .once
      end
    end

    context 'with a deviation of exactly the intent tolerance (1e-6)' do
      let(:params) do
        { scenario: { user_values: {
          'grouped_input_one' => '50.000001',
          'grouped_input_two' => '50.0',
          'grouped_input_three' => '0.0',
          'grouped_input_four' => '0.0',
          'grouped_input_five' => '0.0',
          'grouped_input_six' => '0.0',
          'grouped_input_seven' => '0.0'
        } } }
      end

      it 'accepts and repairs the group' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:ok)
        expect(stored_group_sum).to be_within(1.0e-12).of(100.0)
      end
    end

    context 'with a deviation just above the intent tolerance (1.1e-6)' do
      let(:params) do
        { scenario: { user_values: {
          'grouped_input_one' => '50.0000011',
          'grouped_input_two' => '50.0',
          'grouped_input_three' => '0.0',
          'grouped_input_four' => '0.0',
          'grouped_input_five' => '0.0',
          'grouped_input_six' => '0.0',
          'grouped_input_seven' => '0.0'
        } } }
      end

      it 'refuses the update' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('does not balance')
      end
    end

    context 'with a genuinely imbalanced group (50/30/10) and autobalance on' do
      let(:params) do
        { scenario: { user_values: {
          'grouped_input_one' => '50.0',
          'grouped_input_two' => '30.0',
          'grouped_input_three' => '10.0',
          'grouped_input_four' => '0.0',
          'grouped_input_five' => '0.0',
          'grouped_input_six' => '0.0',
          'grouped_input_seven' => '0.0'
        } } }
      end

      it 'refuses the update loudly' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('does not balance')
      end
    end

    context 'with a drifting group where a zero share is omitted rather than provided' do
      # Six of seven provided; the free member sits at its minimum of 0 and
      # cannot absorb the negative excess (the CannotBalanceError path).
      let(:params) do
        { scenario: { user_values: drifting_values.except('grouped_input_seven') } }
      end

      it 'accepts the update and repairs the group' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:ok)
        expect(stored_group_sum).to be_within(1.0e-12).of(100.0)
      end

      it 'keeps the omitted share at exactly zero, as a balanced value' do
        update_scenario(params:, headers:)
        expect(scenario.balanced_values['grouped_input_seven']).to eq(0.0)
      end
    end

    context 'with a drifting group and autobalance=false' do
      let(:params) do
        { autobalance: 'false', scenario: { user_values: drifting_values } }
      end

      it 'accepts the update and repairs the group' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:ok)
        expect(stored_group_sum).to be_within(1.0e-12).of(100.0)
      end
    end

    context 'when the repair would push a member outside its bounds' do
      # grouped_input_seven sits at its maximum of 50; the group drifts low, so
      # the rescale (× 100/99.9999999) would push it above the maximum.
      let(:params) do
        { scenario: { user_values: {
          'grouped_input_one' => '49.9999999',
          'grouped_input_two' => '0.0',
          'grouped_input_three' => '0.0',
          'grouped_input_four' => '0.0',
          'grouped_input_five' => '0.0',
          'grouped_input_six' => '0.0',
          'grouped_input_seven' => '50.0'
        } } }
      end

      it 'refuses the update, explaining the refused repair' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('cannot be repaired')
        expect(response.body).to include('grouped_input_seven')
        expect(response.body).not_to include('does not balance')
      end
    end

    context 'when the group contains an input whose start value GQL is non-numeric' do
      let(:params) do
        { scenario: { user_values: { 'broken_share_sibling' => '100.0' } } }
      end

      it 'refuses the update, naming the input and its cache error' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('broken_share_input')
        expect(response.body).to include('Non-numeric GQL value: default')
        expect(response.body).not_to include('does not balance')
      end
    end

    context 'with force_balance' do
      before do
        scenario.update!(user_values: {
          'grouped_input_one' => 60.0,
          'grouped_input_two' => 40.0
        })
      end

      let(:params) do
        {
          force_balance: true,
          scenario: { user_values: { 'grouped_input_one' => '50.0' } }
        }
      end

      it 'leaves values provided in the current request alone' do
        update_scenario(params:, headers:)

        expect(response).to have_http_status(:ok)
        expect(scenario.user_values['grouped_input_one']).to eq(50.0)
      end

      it 'overwrites previously-set values to balance the group' do
        update_scenario(params:, headers:)

        expect(scenario.user_values['grouped_input_two']).not_to eq(40.0)
        expect(stored_group_sum).to be_within(1.0e-9).of(100.0)
      end
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
end
