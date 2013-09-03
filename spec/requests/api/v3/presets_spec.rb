require 'spec_helper'

describe 'APIv3 Presets', :etsource_fixture do
  it 'should respond with the presets' do
    get 'api/v3/scenarios/templates'

    json = JSON.parse(response.body)
    json.should have(Preset.all.length).presets

    preset = Preset.all.first
    data   = json.first

    data.should include('id'            => preset.id)
    data.should include('title'         => preset.title)
    data.should include('area_code'     => preset.area_code)
    data.should include('end_year'      => preset.end_year)
    data.should include('display_group' => 'Keizersgracht' )
    data.should_not include('template')
    data.should_not include('source')
    data.should include('description' => preset.description)

    data.should have_key('url')
    data['url'].should match(%r{/scenarios/#{ preset.id }$})
  end
end
