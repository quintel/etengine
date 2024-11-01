# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 Scenarios' do

  let(:scenario) { create(:scenario) }
  let(:json)     { JSON.parse(response.body) }

  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')

    get "/api/v3/scenarios/#{ scenario.id }",
      params: '{',
      headers: access_token_header(create(:user), :read)
  end

  it 'is successful' do
    expect(response.status).to eq(200)
  end

  it 'includes the scenario data' do
    expect(json).to include('id'         => scenario.id)
    expect(json).to include('area_code'  => 'nl')
    expect(json).to include('start_year' => scenario.start_year)
    expect(json).to include('end_year'   => scenario.end_year)
    expect(json).to include('template'   => nil)
    expect(json).to include('source'     => nil)

    expect(json).to have_key('created_at')

    expect(json['url']).to match(%r{/scenarios/#{ scenario.id }$})
  end
end
