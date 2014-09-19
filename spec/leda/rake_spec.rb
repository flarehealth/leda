require 'spec_helper'
require 'rake'

module Leda
  describe Rake do
    let(:configuration) {
      Configuration.new do |leda|
        leda.data_unit 'tlus' do |du|
          du.mock_c
        end

        leda.data_unit 'people' do |du|
          du.mock_a
          du.mock_b
        end
      end
    }

    before do
      ::Rake.application = ::Rake::Application.new
      Leda::Rake.define_tasks(configuration, [:outside_prereq])
    end

    after do
      ::Rake.application.clear
    end

    shared_examples 'a Leda task' do
      it 'exists' do
        expect { task }.to_not raise_error
      end

      it 'has a description' do
        expect(task.comment).not_to be_nil
      end

      it 'depends on the supplied prereqs' do
        expect(task.prerequisites).to eq(%w(outside_prereq))
      end
    end

    shared_examples 'a restore_from task' do
      it_behaves_like 'a Leda task'

      it 'has a source_env argument' do
        expect(task.arg_names).to eq([:source_env])
      end
    end

    describe 'the all:dump task' do
      let(:task) { ::Rake::Task['dump'] }

      it_behaves_like 'a Leda task'
    end

    describe 'an individual unit dump task' do
      let(:task) { ::Rake::Task['people:dump'] }

      it_behaves_like 'a Leda task'
    end

    describe 'an individual store dump task' do
      let(:task) { ::Rake::Task['tlus:mock_c:dump'] }

      it_behaves_like 'a Leda task'
    end

    describe 'the all:restore_from task' do
      let(:task) { ::Rake::Task['restore_from'] }

      it_behaves_like 'a restore_from task'
    end

    describe 'an individual unit restore_from task' do
      let(:task) { ::Rake::Task['tlus:restore_from'] }

      it_behaves_like 'a restore_from task'
    end

    describe 'an individual store restore_from task' do
      let(:task) { ::Rake::Task['people:mock_b:restore_from'] }

      it_behaves_like 'a restore_from task'
    end
  end
end
