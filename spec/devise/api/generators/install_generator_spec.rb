# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Devise::Api::Generators::InstallGenerator do
  describe '.next_migration_number' do
    it 'returns a migration number in the timestamp format' do
      expect(described_class.next_migration_number('db/migrate')).to match(/\A\d{14}\z/)
    end
  end

  describe '#install' do
    let(:destination) { Dir.mktmpdir }
    let(:migration_paths) { Dir.glob(File.join(destination, 'db/migrate/*_create_devise_api_tables.rb')) }
    let(:locale_path) { File.join(destination, 'config/locales/devise_api.en.yml') }

    before do
      described_class.start(['--quiet'], destination_root: destination)
    end

    after do
      FileUtils.remove_entry(destination)
    end

    context 'migration template' do
      it 'creates the migration' do
        expect(migration_paths.size).to eq 1
      end

      it 'renders the migration for the current Active Record version' do
        migration_version = "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"

        expect(File.read(migration_paths.first)).to include("ActiveRecord::Migration#{migration_version}")
      end

      it 'creates the devise api tokens table' do
        expect(File.read(migration_paths.first)).to include('create_table :devise_api_tokens')
      end
    end

    context 'locale file' do
      it 'copies the locale file' do
        expect(File.exist?(locale_path)).to eq true
      end

      it 'copies the gem locale content' do
        gem_locale_path = File.expand_path('../../../../config/locales/en.yml', __dir__)

        expect(File.read(locale_path)).to eq File.read(gem_locale_path)
      end
    end
  end
end
