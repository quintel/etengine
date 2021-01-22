# frozen_string_literal: true

require 'spec_helper'

describe 'Custom curves', :etsource_fixture do
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    NastyCache.instance.expire!
  end
  # rubocop:enable RSpec/BeforeAfterAll

  let(:scenario) { FactoryBot.create(:scenario) }
  let(:url) { "/api/v3/scenarios/#{scenario.id}/custom_curves/#{curve_name}" }

  context 'when requesting all attached curves' do
    let(:url) { "/api/v3/scenarios/#{scenario.id}/custom_curves" }

    context 'when nothing is attached' do
      before { get(url) }

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends no curve data' do
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'with an attached curve for interconnector 1' do
      before do
        put "#{url}/interconnector_1_price", params: {
          file: fixture_file_upload('files/price_curve.csv', 'text/csv')
        }

        get(url)
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends data about one curve' do
        expect(JSON.parse(response.body).length).to eq(1)
      end

      it 'sends data about the attached curve' do
        expect(JSON.parse(response.body)).to include(
          hash_including(
            'key' => 'interconnector_1_price',
            'name' => 'price_curve.csv',
            'size' => 35_039
          )
        )
      end
    end
  end

  context 'with a valid generic curve name' do
    let(:curve_name) { 'generic' }

    context 'when showing a curve and the scenario has nothing attached' do
      before { get(url) }

      it 'is 404 Not Found' do
        expect(response).to be_not_found
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
          'size' => 35_039,
          'stats' => { 'length' => 8760 }
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
          .to change {
            scenario
              .reload
              .attachments
              .find_by(key: 'generic_curve')
              .present?
          }
          .from(false).to(true)
      end
    end

    context 'when uploading a curve as a string' do
      let(:request) do
        put url, params: { file: ("1.0\n" * 8760) }
      end

      it 'sends back JSON data with errors' do
        request

        expect(JSON.parse(response.body)).to include(
          'errors' => ['"file" was not a valid multipart/form-data file']
        )
      end

      it 'sends back JSON data with error keys' do
        request

        expect(JSON.parse(response.body)).to include(
          'error_keys' => %w[not_multipart_form_data]
        )
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
        }
      end

      it 'succeeds' do
        request
        expect(response).to be_successful
      end

      it 'attaches the file' do
        expect { request }
          .to change {
            scenario
              .reload
              .attachments
              .find_by(key: 'generic_curve')
              .present?
          }
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
          .not_to change {
            scenario
              .reload
              .attachments
              .find_by(key: 'generic_curve')
              .present?
          }
          .from(false)
      end
    end

    context 'when uploading a curve exceeding 1MB' do
      let(:file) { Tempfile.new('large_curve') }

      let(:request) do
        put url, params: {
          file: fixture_file_upload(file.path, 'text/csv')
        }
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

      it 'does not change the attachment' do
        expect { request }
          .not_to change {
            scenario
              .reload
              .attachments
              .find_by(key: 'generic_curve')
              .present?
          }
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

      it 'sends no data' do
        request
        expect(response.body).to be_empty
      end

      it 'removes the attachment' do
        expect { request }
          .to change {
            scenario
              .reload
              .attachments
              .find_by(key: 'generic_curve')
              .present?
          }
          .from(true)
          .to(false)
      end
    end

    describe 'when removing and the scenario has no curve attached' do
      let(:request) { delete url }

      it 'is 404 Not Found' do
        request
        expect(response).to be_not_found
      end

      it 'returns JSON representing no curve attached' do
        request
        expect(JSON.parse(response.body)).to eq({})
      end

      it 'does not change the attachment' do
        expect { request }
          .not_to change {
            scenario
              .reload
              .attachments
              .find_by(key: 'generic_curve')
              .present?
          }
          .from(false)
      end
    end
  end

  context 'with a valid price curve name' do
    let(:curve_name) { 'interconnector_1_price' }

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
          'size' => 35_039,
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
          'size' => 35_039,
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

      it 'attaches the file' do
        expect { request }
          .to change {
            scenario
              .reload
              .attachments
              .find_by(key: 'interconnector_1_price_curve')
              .present?
          }
          .from(false).to(true)
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
