require 'spec_helper'

module Leda
  describe Configuration do
    describe 'defined from DSL' do
      let(:actual) do
        Configuration.new do |leda|
          leda.data_unit 'providers' do |c|
            c.postgresql tables: %w(practices offices practitioners)
            c.elasticsearch indexes: %w(sst-practitioners)
          end

          leda.data_unit 'groups' do |c|
            c.postgresql tables: %w(groups mentioned practitioners)
          end
        end
      end

      it 'produces the expected data units' do
        expect(actual.data_units.map(&:name)).to eq(%w(providers groups))
      end

      it 'produces appropriate stores for each data unit' do
        providers_data_unit = actual.data_units.first

        expect(providers_data_unit.stores.map(&:class)).
          to eq([Stores::Postgresql, Stores::Elasticsearch])
      end

      it 'passes the configuration parameters to each store' do
        providers_postgresql_store = actual.data_units.first.stores.first

        expect(providers_postgresql_store.options).to eq({ tables: %w(practices offices practitioners) })
      end
    end

    describe '#update' do
      let(:configuration) { Configuration.new }

      it 'adds to the existing configuration' do
        configuration.update do |leda|
          leda.data_unit 'lookups' do |d|
            d.postgresql tables: %w(zip_codes)
          end
        end

        configuration.update do |leda|
          leda.data_unit 'people' do |d|
            d.postgresql tables: %w(people phone_numbers street_addresses)
          end
        end

        expect(configuration.data_units.map(&:name)).to eq(%w(lookups people))
      end

      it 'returns the configuration' do
        expect(configuration.update { }).to eql(configuration)
      end
    end

    describe '#base_dir=' do
      let(:configuration) { Configuration.new }

      it 'coerces a string into a Pathname' do
        configuration.base_dir = '/foo/quux'

        expect(configuration.base_dir).to eq(Pathname.new('/foo/quux'))
      end

      it 'leaves a Pathname alone' do
        configuration.base_dir = Pathname.new('/bar/baz')
        expect(configuration.base_dir).to eq(Pathname.new('/bar/baz'))
      end
    end
  end
end
