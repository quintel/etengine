# frozen_string_literal: true

require 'spec_helper'

describe 'config/settings.yml' do
  def settings_with(env)
    allow(ENV).to receive(:fetch).and_call_original
    env.each { |key, value| allow(ENV).to receive(:fetch).with(key, anything).and_return(value) }

    YAML.safe_load(ERB.new(Rails.root.join('config/settings.yml').read).result)
  end

  it 'reads a stable VERSION_TAG as a string, as grants are keyed by it' do
    expect(settings_with('VERSION_TAG' => '2025.01')['version_tag']).to eq('2025.01')
  end
end
