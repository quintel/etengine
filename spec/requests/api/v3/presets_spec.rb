require 'spec_helper'

describe 'APIv3 Presets' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  it 'should respond with the presets' do
    get 'api/v3/scenarios/templates'

    json = JSON.parse(response.body)
    json.should have(Preset.all.length).presets

    preset = Preset.all.first
    data   = json.first

    data.should include('id'          => preset.id)
    data.should include('title'       => preset.title)
    data.should include('area_code'   => preset.area_code)
    data.should include('end_year'    => preset.end_year)
    data.should include('template'    => nil)
    data.should include('source'      => nil)
    data.should include('description' => preset.description)

    data.should have_key('url')
    data['url'].should match(%r{/scenarios/#{ preset.id }$})
  end
end
