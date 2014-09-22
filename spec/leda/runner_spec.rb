require 'spec_helper'

module Leda
  describe Runner do
    let(:root) { spec_tmpdir }
    let(:root_s) { root.to_s }

    let(:configuration) {
      Configuration.new do |leda|
        leda.project_root_dir = root
        leda.base_path = 'base'

        leda.data_unit 'tlus' do |du|
          du.mock_c
          du.mock_b
        end

        leda.data_unit 'people' do |du|
          du.mock_a
          du.mock_b
        end
      end
    }

    let(:runner) { Runner.new('dev', configuration) }

    describe '#dump' do
      let(:actual_calls) {
        calls = []
        configuration.data_units.each do |data_unit|
          data_unit.stores.each do |store|
            unless store.dump_directories.empty?
              calls << [data_unit.name, store.name, store.dump_directories.map(&:to_s)]
            end
          end
        end
        calls
      }

      describe 'with no args' do
        before do
          runner.dump
        end

        it 'runs dump on every configured store' do
          expect(actual_calls).to eq([
            ['tlus', 'mock_c', [root_s + '/base/dev/tlus/mock_c']],
            ['tlus', 'mock_b', [root_s + '/base/dev/tlus/mock_b']],
            ['people', 'mock_a', [root_s + '/base/dev/people/mock_a']],
            ['people', 'mock_b', [root_s + '/base/dev/people/mock_b']]
          ])
        end
      end

      describe 'with just a data unit name' do
        before do
          runner.dump('people')
        end

        it 'runs dump on every store in that unit' do
          expect(actual_calls).to eq([
            ['people', 'mock_a', [root_s + '/base/dev/people/mock_a']],
            ['people', 'mock_b', [root_s + '/base/dev/people/mock_b']]
          ])
        end
      end

      describe 'with just a store name' do
        before do
          runner.dump(nil, 'mock_b')
        end

        it 'runs dump on every store of that type' do
          expect(actual_calls).to eq([
            ['tlus', 'mock_b', [root_s + '/base/dev/tlus/mock_b']],
            ['people', 'mock_b', [root_s + '/base/dev/people/mock_b']]
          ])
        end
      end

      describe 'with both a data unit and a store name' do
        before do
          runner.dump('tlus', 'mock_b')
        end

        it 'runs dump on just that combination' do
          expect(actual_calls).to eq([
            ['tlus', 'mock_b', [root_s + '/base/dev/tlus/mock_b']]
          ])
        end
      end

      describe 'with an unknown data unit' do
        it 'throws an exception' do
          expect { runner.dump('frogs', 'mock_a') }.to raise_error(/No data configured that matches frogs:mock_a/)
        end
      end

      describe 'with an unused or unknown store' do
        it 'throws an exception' do
          expect { runner.dump('people', 'mock_c') }.to raise_error(/No data configured that matches people:mock_c/)
        end
      end
    end

    describe '#dump_relative_paths' do
      it 'returns the set of paths for the selected parameters' do
        expect(runner.dump_relative_paths('people').map(&:to_s)).to eq([
          'base/dev/people/mock_a',
          'base/dev/people/mock_b'
        ])
      end
    end

    describe '#restore_from' do
      let(:actual_calls) {
        calls = []
        configuration.data_units.each do |data_unit|
          data_unit.stores.each do |store|
            unless store.restore_from_directories.empty?
              calls << [data_unit.name, store.name, store.restore_from_directories.map(&:to_s)]
            end
          end
        end
        calls
      }

      describe 'with no args' do
        before do
          runner.restore_from('prod')
        end

        it 'runs restore_from on every configured store' do
          expect(actual_calls).to eq([
            ['tlus', 'mock_c', [root_s + '/base/prod/tlus/mock_c']],
            ['tlus', 'mock_b', [root_s + '/base/prod/tlus/mock_b']],
            ['people', 'mock_a', [root_s + '/base/prod/people/mock_a']],
            ['people', 'mock_b', [root_s + '/base/prod/people/mock_b']]
          ])
        end
      end

      describe 'with just a data unit name' do
        before do
          runner.restore_from('stg', 'people')
        end

        it 'runs restore_from on every store in that unit' do
          expect(actual_calls).to eq([
            ['people', 'mock_a', [root_s + '/base/stg/people/mock_a']],
            ['people', 'mock_b', [root_s + '/base/stg/people/mock_b']]
          ])
        end
      end

      describe 'with just a store name' do
        before do
          runner.restore_from('local', nil, 'mock_b')
        end

        it 'runs restore_from on every store of that type' do
          expect(actual_calls).to eq([
            ['tlus', 'mock_b', [root_s + '/base/local/tlus/mock_b']],
            ['people', 'mock_b', [root_s + '/base/local/people/mock_b']]
          ])
        end
      end

      describe 'with both a data unit and a store name' do
        before do
          runner.restore_from('super-prod', 'tlus', 'mock_b')
        end

        it 'runs restore_from on just that combination' do
          expect(actual_calls).to eq([
            ['tlus', 'mock_b', [root_s + '/base/super-prod/tlus/mock_b']]
          ])
        end
      end

      describe 'with an unknown data unit' do
        it 'throws an exception' do
          expect { runner.restore_from('prod', 'frogs', 'mock_a') }.to raise_error(/No data configured that matches frogs:mock_a/)
        end
      end

      describe 'with an unused or unknown store' do
        it 'throws an exception' do
          expect { runner.restore_from('prod', 'people', 'mock_c') }.to raise_error(/No data configured that matches people:mock_c/)
        end
      end
    end
  end
end
