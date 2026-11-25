# frozen_string_literal: true

require 'spec_helper'

describe 'Custom curves', :etsource_fixture do
  def public_curves
    Etsource::Config.user_curves.reject { |_key, value| value.internal? }
  end

  before(:all) do
    NastyCache.instance.expire!
  end

  # Access is determined solely by the token's scenario_access grant. The scenario is bound (saved
  # in MyETM) so that the grant is the only route to access beyond what is public.
  let(:scenario) { FactoryBot.create(:scenario, bound: true) }
  let(:url) { "/api/v3/scenarios/#{scenario.id}/custom_curves/#{curve_name}" }
  let(:user) { create(:user) }
  let(:token_header) { access_token_header(user, :read) }
  let(:write_header) { granted_header(:write) }
  let(:delete_header) { granted_header(:delete) }

  def granted_header(scopes)
    access_token_header(user, scopes, scenario_access: scenario_grant(write: [scenario.id]))
  end


  context 'when requesting all curves with include_unattached=true' do
    let(:url) { "/api/v3/scenarios/#{scenario.id}/custom_curves?include_unattached=true" }

    context 'when no user curves are present' do
      before { get(url, headers: token_header) }

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends data about all public curves' do
        expect(JSON.parse(response.body).length).to eq(public_curves.length)
      end
    end
  end

  context 'when requesting all attached curves' do
    let(:url) { "/api/v3/scenarios/#{scenario.id}/custom_curves" }

    context 'when no user curves are present' do
      before { get(url, headers: token_header) }

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends no curve data' do
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'with a user curve for interconnector 1' do
      before do
        put "#{url}/interconnector_1_price", params: {
          file: fixture_file_upload('price_curve.csv', 'text/csv')
        }, headers: write_header

        get(url, headers: token_header)
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends data about one curve' do
        expect(JSON.parse(response.body).length).to eq(1)
      end

      it 'includes details about the user curve' do
        expect(JSON.parse(response.body)).to include(
          hash_including(
            'key' => 'interconnector_1_price',
            'name' => 'price_curve',
            'size' => 78_843
          )
        )
      end
    end
  end

  context 'with no attached curves and include_internal and include_unattached both set' do
    let(:url) do
      "/api/v3/scenarios/#{scenario.id}/custom_curves" \
        '?include_internal=true&include_unattached=true'
    end

    before { get(url, headers: token_header) }

    it 'succeeds' do
      expect(response).to be_successful
    end

    it 'sends data about all available curves' do
      expect(JSON.parse(response.body).length).to eq(Etsource::Config.user_curves.length)
    end
  end

  context 'with an attached internal curve and setting an include_internal param' do
    let(:url) { "/api/v3/scenarios/#{scenario.id}/custom_curves?include_internal=true" }

    before do
      put "#{url.split('?').first}/internal", params: {
        file: fixture_file_upload('random_curve.csv', 'text/csv')
      }, headers: write_header

      get(url, headers: token_header)
    end

    it 'succeeds' do
      expect(response).to be_successful
    end

    it 'sends data for attached curves only' do
      expect(JSON.parse(response.body).length).to eq(1)
    end

    it 'sends data about the attached curve' do
      expect(JSON.parse(response.body).first).to include(
        'key' => 'internal',
        'internal' => true
      )
    end
  end

  context 'with a valid generic curve name' do
    let(:curve_name) { 'generic' }

    context 'when no user curve is stored' do
      before { get(url, headers: token_header) }

      it 'is 404 Not Found' do
        expect(response).to be_not_found
      end
    end

    context 'when showing a stored user curve' do
      before do
        put url, params: {
          file: fixture_file_upload('price_curve.csv', 'text/csv')
        }, headers: write_header

        get(url, headers: token_header)
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends back JSON data about the curve' do
        expect(JSON.parse(response.body)).to include(
          'name' => 'price_curve',
          'size' => 78_843,
          'stats' => { 'length' => 8760, 'min_at' => 0, 'max_at' => 1 }
        )
      end
    end

    context 'when uploading a valid user curve file' do
      let(:request) do
        put url, params: {
          file: fixture_file_upload('price_curve.csv', 'text/csv')
        }, headers: write_header
      end

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'sends back JSON data about the curve' do
        request

        expect(JSON.parse(response.body)).to include(
          'name' => 'price_curve',
          'size' => 78_843
        )
      end

      it 'creates the user curve record' do
        expect { request }
          .to change {
            scenario.reload.user_curves.exists?(key: 'generic_curve')
          }
          .from(false).to(true)
      end
    end

    context 'when downloading a curve as CSV' do
      before do
        put url, params: {
          file: fixture_file_upload('price_curve.csv', 'text/csv')
        }, headers: write_header

        get(url, headers: { 'Accept' => 'text/csv' }.merge(token_header))
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends back CSV data about the curve' do
        expect(response.body.strip).to eq(File.read('spec/fixtures/files/price_curve.csv').strip)
      end
    end

    context 'when downloading an unattached curve as CSV' do
      before do
        get(url, headers: { 'Accept' => 'text/csv' }.merge(token_header))
      end

      it 'response with Not Found' do
        expect(response).to be_not_found
      end
    end

    context 'when removing a user curve' do
      before do
        put url, params: {
          file: fixture_file_upload('price_curve.csv', 'text/csv')
        }, headers: delete_header
      end

      let(:request) { delete url, headers: delete_header }

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'sends no data' do
        request
        expect(response.body).to be_empty
      end

      it 'removes the user curve' do
        expect { request }
          .to change {
            scenario.reload.user_curves.exists?(key: 'generic_curve')
          }
          .from(true).to(false)
      end
    end

    context 'when uploading an invalid curve' do
      let(:request) do
        put url, params: {
          file: fixture_file_upload('invalid_price_curve.csv', 'text/csv')
        }, headers: write_header
      end

      it 'fails' do
        request
        expect(response).not_to be_successful
      end

      it 'sends back JSON data with errors' do
        request

        expect(JSON.parse(response.body)).to include(
          'errors' => [
            'Curve must have 8760 numeric values, one for each hour in ' \
              'a typical year',
            'Curve must only contain numeric values'
          ]
        )
      end

      it 'sends back JSON data with error keys' do
        request

        expect(JSON.parse(response.body)).to include(
          'error_keys' => %w[wrong_length illegal_value]
        )
      end

      it 'does not create a user curve' do
         expect { request }
           .not_to change {
             scenario.reload.user_curves.exists?(key: 'generic_curve')
           }
           .from(false)
      end
    end

    context 'when uploading a curve exceeding 1MB' do
      let(:file) { Tempfile.new('large_curve') }

      let(:request) do
        put url, params: {
          file: fixture_file_upload(file.path, 'text/csv')
        }, headers: write_header
      end

      before { file.write(((['1' * 120] * 8760).join("\n") + "\n")) }

      after { file.unlink }

      it 'fails' do
        request
        expect(response).not_to be_successful
      end

      it 'sends back JSON data with errors' do
        request

        expect(JSON.parse(response.body)).to include(
          'errors' => ['Curve should not be larger than 1MB']
        )
      end

      it 'sends back JSON data with error keys' do
        request

        expect(JSON.parse(response.body)).to include(
          'error_keys' => %w[file_too_large]
        )
      end

      it 'does not create a user curve' do
        expect { request }
          .not_to change {
            scenario.reload.user_curves.exists?(key: 'generic_curve')
         }
         .from(false)
      end
    end

    context 'when uploading a valid curve file with a byte order mark' do
      let(:file) do
        file = Tempfile.new('bom_curve')
        file.write("\xEF\xBB\xBF")
        file.write("1.0\n" * 8760)
        file
      end

      let(:request) do
        put url, params: {
          file: fixture_file_upload(file.path, 'text/csv')
        }, headers: write_header
      end

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'creates the user curve record' do
        expect { request }
          .to change {
            scenario.reload.user_curves.exists?(key: 'generic_curve')
          }
          .from(false).to(true)
      end
    end

    describe 'when removing and the scenario has no curve attached' do
      let(:request) { delete url, headers: delete_header }

      it 'is 404 Not Found' do
        request
        expect(response).to be_not_found
      end

      it 'does not change the user curve' do
        expect { request }
          .not_to change {
            scenario.reload.user_curves.exists?(key: 'generic_curve')
          }
          .from(false)
      end
    end

    describe 'access' do
      let(:attached) { scenario.reload.user_curves.exists?(key: 'generic_curve') }

      def attach_curve
        put url, params: { file: fixture_file_upload('price_curve.csv', 'text/csv') },
          headers: write_header
        expect(response).to be_successful
      end

      def upload
        put url, params: { file: fixture_file_upload('price_curve.csv', 'text/csv') }, headers:
      end

      shared_examples_for 'a readable curve' do
        it 'allows showing the curve' do
          attach_curve
          get(url, headers:)
          expect(response).to have_http_status(:ok)
        end
      end

      shared_examples_for 'an unreadable curve' do
        it 'refuses showing the curve' do
          attach_curve
          get(url, headers:)
          expect(response).to have_http_status(:not_found)
        end
      end

      shared_examples_for 'a writable curve' do
        it 'allows uploading the curve' do
          upload
          expect(response).to have_http_status(:ok)
          expect(attached).to be(true)
        end

        it 'allows removing the curve' do
          attach_curve
          delete(url, headers:)
          expect(response).to have_http_status(:no_content)
          expect(attached).to be(false)
        end
      end

      shared_examples_for 'a non-writable curve' do |status|
        it "refuses uploading the curve with #{status}" do
          upload
          expect(response).to have_http_status(status)
          expect(attached).to be(false)
        end

        it "refuses removing the curve with #{status}" do
          attach_curve
          delete(url, headers:)
          expect(response).to have_http_status(status)
          expect(attached).to be(true)
        end
      end

      context 'when the scenario is public' do
        context 'when the token has no grant for the scenario' do
          let(:headers) { access_token_header(user, :delete) }

          it_behaves_like 'a readable curve'
          it_behaves_like 'a non-writable curve', :forbidden

          it 'explains the refusal' do
            attach_curve
            delete(url, headers:)
            expect(response.parsed_body).to eq('errors' => ['Scenario does not belong to you'])
          end
        end

        context 'when the token grants read access (viewer)' do
          let(:headers) do
            access_token_header(user, :delete, scenario_access: scenario_grant(read: [scenario.id]))
          end

          it_behaves_like 'a readable curve'
          it_behaves_like 'a non-writable curve', :forbidden
        end

        context 'when the token grants write access' do
          let(:headers) { delete_header }

          it_behaves_like 'a readable curve'
          it_behaves_like 'a writable curve'
        end

        context 'when the token grants write access without the scenarios:write scope' do
          let(:headers) { granted_header(:read) }

          it_behaves_like 'a readable curve'
          it_behaves_like 'a non-writable curve', :forbidden
        end
      end

      context 'when the scenario is private' do
        before { scenario.update!(private: true) }

        context 'when the token has no grant for the scenario' do
          let(:headers) { access_token_header(user, :delete) }

          it_behaves_like 'an unreadable curve'
          it_behaves_like 'a non-writable curve', :not_found
        end

        context 'when the token grants read access (viewer)' do
          let(:headers) do
            access_token_header(user, :delete, scenario_access: scenario_grant(read: [scenario.id]))
          end

          it_behaves_like 'a readable curve'
          it_behaves_like 'a non-writable curve', :not_found
        end

        context 'when the token grants write access' do
          let(:headers) { delete_header }

          it_behaves_like 'a readable curve'
          it_behaves_like 'a writable curve'
        end
      end
    end
  end

  context 'with a valid price curve name' do
    let(:curve_name) { 'interconnector_1_price' }

    context 'when showing a curve' do
      before do
        put url, params: {
          file: fixture_file_upload('price_curve.csv', 'text/csv')
        }, headers: write_header

        get(url, headers: token_header)
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends back JSON data about the curve' do
        json = JSON.parse(response.body)

        expect(json).to include(
          'name' => 'price_curve',
          'key' => 'interconnector_1_price',
          'stats' => hash_including(
            'length' => 8760,
            'min' => 1.0,
            'max' => 2.0,
            'mean' => 1.5
          )
        )
      end
    end

    context 'when uploading a valid curve file' do
      let(:request) do
        put url, params: {
          file: fixture_file_upload('price_curve.csv', 'text/csv')
        }, headers: write_header
      end

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'sends back JSON data about the curve' do
        request

        expect(JSON.parse(response.body)).to include(
          'name' => 'price_curve',
          'key' => 'interconnector_1_price',
          'stats' => {
            'length' => 8760,
            'max' => 2.0,
            'max_at' => 1,
            'mean' => 1.5,
            'min' => 1.0,
            'min_at' => 0
          }
        )
      end

      it 'creates a user curve with correct key' do
        expect { request }
          .to change {
            scenario.reload.user_curves.exists?(key: 'interconnector_1_price_curve')
          }
          .from(false).to(true)
      end
    end
  end
end
