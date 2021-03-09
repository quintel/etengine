# frozen_string_literal: true

require 'spec_helper'

describe 'ESDL files', :etsource_fixture do
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    NastyCache.instance.expire!
  end
  # rubocop:enable RSpec/BeforeAfterAll

  let(:scenario) { FactoryBot.create(:scenario) }
  let(:url) { "/api/v3/scenarios/#{scenario.id}/esdl_file" }

  context('when requesting attached esdl file') do
    context 'when nothing is attached' do
      before { get(url) }

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends no esdl data' do
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context 'when file is attached' do
      before do
        put url, params: {
          file: fixture_file_upload('files/valid_esdl_file.esdl', 'text/xml')
        }

        get(url)
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends 2 pieces of data about the esdl file' do
        expect(JSON.parse(response.body).length).to eq(2)
      end

      it 'sends data about the esdl file' do
        expect(JSON.parse(response.body)).to include(
          'filename' => 'valid_esdl_file.esdl'
        )
      end
    end

    context 'with download parameter set' do
      before do
        put url, params: {
          file: fixture_file_upload('files/valid_esdl_file.esdl', 'text/xml'),
        }

        get(url, params: { download: true })
      end

      it 'succeeds' do
        expect(response).to be_successful
      end

      it 'sends 3 pieces of data about the esdl file' do
        expect(JSON.parse(response.body).length).to eq(3)
      end

      it 'sends data about the esdl file' do
        expect(JSON.parse(response.body)).to include(
          'filename' => 'valid_esdl_file.esdl'
        )
      end

      it 'sends the full esdl file' do
        expect(JSON.parse(response.body)['file']).to eq(
          fixture_file_upload('files/valid_esdl_file.esdl', 'text/xml').read
        )
      end
    end
  end

  context('when uploading a valid esdl file') do
    let(:request) do
      put url, params: {
        file: fixture_file_upload('files/valid_esdl_file.esdl', 'text/xml'),
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
            .find_by(key: 'esdl_file')
            .present?
        }
        .from(false).to(true)
    end
  end

  context('when uploading an esdl file larger than 5MB') do
    let(:file) { Tempfile.new('large_esdl_file.esdl') }
    let(:request) do
      put url, params: {
        file: fixture_file_upload(file.path, 'text/xml')
      }
    end

    before do
      file.write(
        "<?xml version='1.0' encoding='UTF-8'?>\n
        <esdl:EnergySystem xmlns:xsi='foo' xmlns:esdl='foo' name='my_esdl' id='1'>\n" +
        (["<measures id='measures'>\n
            <measure xsi:type='esdl:Measure'>\n
              <asset xsi:type='esdl:WindTurbine' id='1' fullLoadHours='1920' power='3000000.0'/>\n
            </measure>\n
          </measures>"] * 25_000).join("\n") +
        '</esdl:EnergySystem>'
      )
      file.rewind
    end

    after do
      file.close
      file.unlink
    end

    it 'fails' do
      request
      expect(response).not_to be_successful
    end

    it 'sends back JSON data with errors' do
      request

      expect(JSON.parse(response.body)).to include(
        'errors' => ['ESDL file should not be larger than 5MB']
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
            .find_by(key: 'esdl_file')
            .present?
        }
        .from(false)
    end
  end

  context('when UPDATE and wrong content-type') do
    let(:file) { '12345' }
    let(:request) do
      put url, params: {
        file: file
      }
    end

    it 'fails' do
      request
      expect(response).not_to be_successful
    end

    it 'sends back JSON data with errors' do
      request

      expect(JSON.parse(response.body)).to include(
        'errors' => ["\"file\" was not a valid multipart/form-data file"]
      )
    end

    it 'sends back JSON data with error keys' do
      request

      expect(JSON.parse(response.body)).to include(
        'error_keys' => %w[not_multipart_form_data]
      )
    end

    it 'does not change the attachment' do
      expect { request }
        .not_to change {
          scenario
            .reload
            .attachments
            .find_by(key: 'esdl_file')
            .present?
        }
        .from(false)
    end

  end
end
