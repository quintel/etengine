# frozen_string_literal: true

require 'spec_helper'

describe 'FileUploadHandler' do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:file_handler) { FileUploadHandler.new(file, 'my_esdl', key, scenario) }

  context 'when a file was already attached' do
    let(:key) { 'esdl_file' }
    let(:file) { fixture_file_upload('files/valid_esdl_file.esdl', 'text/xml').read }

    before { file_handler.call }

    it 'is not valid' do
      expect(file_handler).not_to be_valid
    end
  end

  context 'when attaching a valid esdl file' do
    let(:key) { 'esdl_file' }
    let(:file) { fixture_file_upload('files/valid_esdl_file.esdl', 'text/xml').read }

    it 'is valid' do
      expect(file_handler).to be_valid
    end

    it 'attaches the file' do
      expect { file_handler.call }
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

  context 'when attachting a file that is not content type xml' do
    let(:key) { 'esdl_file' }
    let(:file) { ("1.0\n" * 8760) }

    it 'is not valid' do
      expect(file_handler).not_to be_valid
    end

    it 'returns errors' do
      file_handler.valid?

      expect(file_handler.errors).to include(
        'This file does not contain ESDL'
      )
    end
  end

  context 'when trying to upload a curve' do
    let(:key) { 'generic_curve' }
    let(:file) { ("1.0\n" * 8760) }

    it 'is not valid' do
      expect(file_handler).not_to be_valid
    end

    it 'returns errors' do
      file_handler.valid?

      expect(file_handler.errors).to include(
        "This handler cannot attach files of type #{key}."
      )
    end
  end
end
