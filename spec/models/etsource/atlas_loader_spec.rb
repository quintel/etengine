require 'spec_helper'

module Etsource
  describe AtlasLoader do
    let(:yml) { Rails.root.join('spec/fixtures/etsource/static/.') }
    let(:dir) { Pathname.new(Dir.mktmpdir) }

    describe AtlasLoader::PreCalculated do
      let(:loader) { AtlasLoader::PreCalculated.new(dir) }

      before(:each) do
        FileUtils.cp_r(yml, dir)
      end

      context 'loading a dataset' do
        it 'loads the dataset from the production-mode file' do
          expect(loader.load(:nl)).to be_an(Atlas::ProductionMode)
        end

        it 'raises an error when the production-mode file does not exist' do
          dir.join('nl.yml').delete
          expect { loader.load(:nl) }.to raise_error(/no atlas data/i)
        end

        it 'raises an error when no such region exists' do
          expect { loader.load(:nope) }.to raise_error(/no atlas data/i)
        end
      end # loading a dataset
    end # PreCalculated

    describe AtlasLoader::Lazy do
      let(:loader) { AtlasLoader::Lazy.new(dir) }
      let(:subdir) { dir.join('lazy') }

      before(:each) do
        FileUtils.mkdir(subdir)
        FileUtils.cp_r(yml, subdir)
      end

      context 'loading a dataset' do
        it 'loads the dataset from the production-mode file' do
          expect(loader.load(:nl)).to be_an(Atlas::ProductionMode)
        end

        xit 'loads the dataset when the production-mode file does not exist' do
          # Bad query value in a document: invalid value for convert(): ""
          subdir.join('nl.yml').delete
          expect(loader.load(:nl)).to be_an(Atlas::ProductionMode)
        end

        it 'raises an error when no such region exists' do
          expect { loader.load(:nope) }.
            to raise_error(Atlas::DocumentNotFoundError)
        end
      end # loading a dataset
    end # AtlasLoader::PreCalculated
  end # AtlasLoader
end # Etsource
