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

  def update_scenario(params = {})
    put("/api/v3/scenarios/#{scenario.id}", params:)
    scenario.reload
  end

  context 'when setting the scenario keep_compatible to true' do
    let(:params) { { scenario: { keep_compatible: true } } }

    it 'sets keep_compatible to true' do
      expect { update_scenario(params) }.to change(scenario, :keep_compatible?).from(false).to(true)
    end

    it 'does not change api_read_only' do
      expect { update_scenario(params) }.not_to change(scenario, :api_read_only?).from(false)
    end
  end

  context 'when setting the scenario read_only to true' do
    let(:params) { { scenario: { read_only: true } } }

    it 'sets api_read_only to true' do
      expect { update_scenario(params) }
        .to change(scenario, :api_read_only?)
        .from(false).to(true)
    end

    it 'sets keep_compatible to true' do
      expect { update_scenario(params) }.to change(scenario, :keep_compatible?).from(false).to(true)
    end
  end

  # Legacy attribute.
  context 'when setting protected to true' do
    let(:params) { { scenario: { protected: true } } }

    it 'sets api_read_only to true' do
      expect { update_scenario(params) }
        .to change(scenario, :api_read_only?)
        .from(false).to(true)
    end

    it 'sets keep_compatible to true' do
      expect { update_scenario(params) }
        .to change(scenario, :keep_compatible?)
        .from(false).to(true)
    end
  end

  context 'when setting the scenario read_only to false' do
    let(:params) { { scenario: { read_only: false } } }

    it 'does not change api_read_only' do
      expect { update_scenario(params) }.not_to change(scenario, :api_read_only?).from(false)
    end

    it 'does not change keep_compatible' do
      expect { update_scenario(params) }.not_to change(scenario, :keep_compatible?).from(false)
    end
  end

  context 'when setting the scenario read_only to false and protected to true' do
    let(:params) { { scenario: { read_only: false, protected: true } } }

    it 'does not change api_read_only' do
      expect { update_scenario(params) }.not_to change(scenario, :api_read_only?).from(false)
    end

    it 'does not change keep_compatible' do
      expect { update_scenario(params) }.not_to change(scenario, :keep_compatible?).from(false)
    end
  end

  context 'with a keep-compatible scenario' do
    before do
      scenario.update!(keep_compatible: true)
    end

    context 'when setting keep_compatible to false' do
      let(:params) { { scenario: { keep_compatible: false } } }

      it 'sets keep_compatible to false' do
        expect { update_scenario(params) }
          .to change(scenario, :keep_compatible?)
          .from(true).to(false)
      end
    end

    context 'when setting read_only to true, keep_compatible to false' do
      let(:params) { { scenario: { read_only: true, keep_comptible: false } } }

      it 'does not change keep_compatible' do
        expect { update_scenario(params) }
          .not_to change(scenario, :keep_compatible?)
          .from(true)
      end

      it 'sets api_read_only to true' do
        expect { update_scenario(params) }
          .to change(scenario, :api_read_only?)
          .from(false).to(true)
      end
    end
  end
end
