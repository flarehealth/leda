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
  end
end
