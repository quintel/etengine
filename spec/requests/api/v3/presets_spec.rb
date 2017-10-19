require 'spec_helper'

describe 'APIv3 Presets', :etsource_fixture do
  it 'should respond with the presets' do
    get '/api/v3/scenarios/templates'

    json = JSON.parse(response.body)
    expect(json.size).to eq(Preset.visible.length)

    preset = Preset.all.first
    data   = json.first

    expect(data).to include('id'            => preset.id)
    expect(data).to include('title'         => preset.title)
    expect(data).to include('area_code'     => preset.area_code)
    expect(data).to include('end_year'      => preset.end_year)
    expect(data).to include('display_group' => 'Keizersgracht' )
    expect(data).not_to include('template')
    expect(data).not_to include('source')
    expect(data).to include('description' => preset.description)

    expect(data).to have_key('url')
    expect(data['url']).to match(%r{/scenarios/#{ preset.id }$})
  end
end
