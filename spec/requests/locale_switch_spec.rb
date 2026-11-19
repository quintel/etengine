require 'spec_helper'

describe 'Switching locale' do
  it 'redirects to the same path without the locale parameter' do
    get('/', params: { locale: 'nl' })

    expect(response).to redirect_to('/')
  end

  it 'keeps the other query parameters' do
    get('/', params: { locale: 'nl', page: '2' })

    expect(response).to redirect_to('/?page=2')
  end

  it 'never redirects to a host taken from the query string' do
    get('/', params: { locale: 'nl', host: 'evil.example', protocol: 'https' })

    expect(URI(response.location).host).to eq('www.example.com')
  end

  it 'remembers the chosen locale' do
    get('/', params: { locale: 'nl' })

    expect(session[:locale]).to eq('nl')
  end
end
