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

  context 'when setting the scenario keep_compatible to true' do
    let(:params) { { scenario: { keep_compatible: true } } }

    it 'sets keep_compatible to true' do
      expect { update_scenario(params:) }
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
      scenario.update!(owner:, private: false)
    end

    let(:owner) { create(:user) }

    it 'sets private to true' do
      expect do
        update_scenario(
          params: { scenario: { private: true } },
          headers: access_token_header(owner, :write)
        )
      end.to change(scenario, :private?).from(false).to(true)
    end
  end

  context 'when setting an owned private scenario to be public' do
    before do
      scenario.update!(owner:, private: true)
    end

    let(:owner) { create(:user) }

    it 'sets private to false' do
      expect do
        update_scenario(
          params: { scenario: { private: false } },
          headers: access_token_header(owner, :write)
        )
      end.to change(scenario, :private?).from(true).to(false)
    end
  end

  context 'with a keep-compatible scenario' do
    before do
      scenario.update!(keep_compatible: true)
    end

    context 'when setting keep_compatible to false' do
      let(:params) { { scenario: { keep_compatible: false } } }

      it 'sets keep_compatible to false' do
        expect { update_scenario(params:) }
          .to change(scenario, :keep_compatible?)
          .from(true).to(false)
      end
    end
  end
end
