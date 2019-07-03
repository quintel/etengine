require 'spec_helper'

describe 'Custom curves', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  let(:scenario) { FactoryBot.create(:scenario) }
  let(:url) { "/api/v3/scenarios/#{scenario.id}/custom_curves/#{curve_name}" }

  context 'with a valid curve name' do
    let(:curve_name) { 'imported_electricity_price' }

    context 'when showing a curve and the scenario has nothing attached' do
      before { get(url) }

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends an empty JSON object' do
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context 'when showing a curve' do
      before do
        put url, params: {
          file: fixture_file_upload('files/price_curve.csv', 'text/csv')
        }

        get(url)
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends back JSON data about the curve' do
        expect(JSON.parse(response.body)).to include(
          'name' => 'price_curve.csv',
          'size' => 35_039
        )
      end
    end

    context 'when uploading a valid curve file' do
      let(:request) do
        put url, params: {
          file: fixture_file_upload('files/price_curve.csv', 'text/csv')
        }
      end

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'sends back JSON data about the curve' do
        request

        expect(JSON.parse(response.body)).to include(
          'name' => 'price_curve.csv',
          'size' => 35_039
        )
      end

      it 'attaches the file' do
        expect { request }
          .to change { scenario.reload.imported_electricity_price_curve.attached? }
          .from(false).to(true)
      end
    end

    context 'when uploading an invalid curve' do
      let(:request) do
        put url, params: {
          file: fixture_file_upload('files/invalid_price_curve.csv', 'text/csv')
        }
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

      it 'does not change the attachment' do
        expect { request }
          .not_to change { scenario.reload.imported_electricity_price_curve.attached? }
          .from(false)
      end
    end

    context 'when uploading a curve exceeding 1MB', :focus do
      let(:file) { Tempfile.new('large_curve') }

      let(:request) do
        put url, params: {
          file: fixture_file_upload(file.path, 'text/csv')
        }
      end

      before { file.write(((['1'*120]*8760).join("\n") + "\n")) }

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

      it 'does not change the attachment' do
        expect { request }
          .not_to change { scenario.reload.imported_electricity_price_curve.attached? }
          .from(false)
      end
    end

    context 'when removing an attached curve' do
      before do
        put url, params: {
          file: fixture_file_upload('files/price_curve.csv', 'text/csv')
        }
      end

      let(:request) { delete url }

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'returns JSON representing no curve attached' do
        request
        expect(JSON.parse(response.body)).to eq({})
      end

      it 'removes the attachment' do
        expect { request }
          .to change { scenario.reload.imported_electricity_price_curve.attached? }
          .from(true)
          .to(false)
      end
    end

    describe 'when removing and the scenario has no curve attached' do
      let(:request) { delete url }

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'returns JSON representing no curve attached' do
        request
        expect(JSON.parse(response.body)).to eq({})
      end

      it 'does not change the attachment' do
        expect { request }
          .not_to change { scenario.reload.imported_electricity_price_curve.attached? }
          .from(false)
      end
    end
  end

  context 'with an invalid curve name' do
    let(:curve_name) { 'no_such_curve' }

    it 'rejects the request' do
      put url, params: {
        file: fixture_file_upload('files/price_curve.csv', 'text/csv')
      }

      expect(response).not_to be_successful
    end
  end
end
