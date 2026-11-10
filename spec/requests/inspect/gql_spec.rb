# frozen_string_literal: true

require 'spec_helper'

describe 'Running GQL in the inspect pages', :etsource_fixture do
  let(:scenario) { create(:scenario) }
  let(:base_path) { "/inspect/#{scenario.id}" }

  def sign_in(user, admin: false)
    generate_jwt(user)

    payload = jwt_payload(user)
    payload['user']['admin'] = admin

    cookies[Identity.config.session_cookie_name] =
      JWT.encode(payload, AuthorizationHelper.key, 'RS256', kid: 'test_key')
  end

  # The authenticity token of the form posting to the given path.
  def form_token(path)
    response.parsed_body.at_css(%(form[action="#{path}"] input[name="authenticity_token"]))['value']
  end

  def with_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  context 'when signed in as an admin' do
    before { sign_in(create(:user), admin: true) }

    describe 'the GQL sandbox' do
      let(:path) { "#{base_path}/gqueries/test" }

      it 'does not run a query sent with GET' do
        get path, params: { query: 'Q(bar_demand)' }

        expect(response.parsed_body.css('h2').map(&:text)).not_to include('Result')
      end

      it 'runs a query sent with POST' do
        post path, params: { query: 'Q(bar_demand)' }

        expect(response.parsed_body.css('h2').map(&:text)).to include('Result')
      end

      it 'runs a query posted from its own form' do
        with_forgery_protection do
          get path
          post path, params: { query: 'Q(bar_demand)', authenticity_token: form_token(path) }
        end

        expect(response.parsed_body.css('h2').map(&:text)).to include('Result')
      end

      it 'refuses a POST without an authenticity token' do
        with_forgery_protection do
          expect { post(path, params: { query: 'Q(bar_demand)' }) }
            .to raise_error(ActionController::InvalidAuthenticityToken)
        end
      end
    end

    describe 'the GQL debugger' do
      let(:path) { "#{base_path}/debug/gquery" }

      it 'does not run a query sent with GET' do
        get path, params: { gquery: 'Q(bar_demand)' }

        expect(response.parsed_body.css('#debugger p.gql')).to be_empty
      end

      it 'runs a query posted from its own form' do
        with_forgery_protection do
          get path
          post path, params: { gquery: 'Q(bar_demand)', authenticity_token: form_token(path) }
        end

        expect(response.parsed_body.css('#debugger p.gql')).not_to be_empty
      end

      it 'refuses a POST without an authenticity token' do
        with_forgery_protection do
          expect { post(path, params: { gquery: 'Q(bar_demand)' }) }
            .to raise_error(ActionController::InvalidAuthenticityToken)
        end
      end
    end

    describe 'clearing the GQL log' do
      let(:path) { "#{base_path}/gql/log" }
      let(:file) { Rails.root.join('log/gql.log') }

      before do
        allow(File).to receive(:truncate)
        allow(IO).to receive(:readlines).and_call_original
        allow(IO).to receive(:readlines).with(file).and_return([])
      end

      it 'keeps the log on GET' do
        get path, params: { reset: 1 }

        expect(File).not_to have_received(:truncate)
      end

      it 'clears the log on POST' do
        post path, params: { reset: 1 }

        expect(File).to have_received(:truncate).with(file, 0)
      end
    end

    describe 'clearing the GQL warnings' do
      let(:path) { "#{base_path}/gql/warnings" }
      let(:file) { Rails.root.join('log/warnings.log') }

      before do
        allow(File).to receive(:truncate)
        allow(IO).to receive(:readlines).and_call_original
        allow(IO).to receive(:readlines).with(file).and_return([])
      end

      it 'keeps the warnings on GET' do
        get path, params: { reset: 1 }

        expect(File).not_to have_received(:truncate)
      end

      it 'clears the warnings on POST' do
        post path, params: { reset: 1 }

        expect(File).to have_received(:truncate).with(file, 0)
      end
    end
  end

  context 'when signed in as a user' do
    before { sign_in(create(:user)) }

    it 'does not run a query in the sandbox' do
      post "#{base_path}/gqueries/test", params: { query: 'Q(bar_demand)' }

      expect(response).to have_http_status(:not_found)
    end

    it 'does not run a query in the debugger' do
      post "#{base_path}/debug/gquery", params: { gquery: 'Q(bar_demand)' }

      expect(response).to have_http_status(:not_found)
    end
  end
end
