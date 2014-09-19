require 'leda'
require 'rake'

module Leda
  module Rake
    extend self

    ##
    # Defines aggregate and individual dump & restore tasks based on the given
    # {{Configuration}}. In real life, you'll probably want to call this from
    # inside a `namespace` block:
    #
    #     # In Rakefile
    #     namespace 'data' do
    #       Leda::Rake.define_tasks(Leda.configuration, [:environment])
    #     end
    def define_tasks(configuration, outside_prerequisites=[])
      define_dump_task(configuration, outside_prerequisites,
        "Dump all Leda-configured data", nil, nil)
      define_restore_from_task(configuration, outside_prerequisites,
        "Restore all Leda-configured data from the specified env", nil, nil)

      configuration.data_units.each do |data_unit|
        define_dump_task(configuration, outside_prerequisites,
          "Dump all data for #{data_unit.name} from the current env",
          data_unit.name, nil)
        define_restore_from_task(configuration, outside_prerequisites,
          "Restore all data for #{data_unit.name} from the specified env into the current env",
          data_unit.name, nil)

        data_unit.stores.each do |store|
          define_dump_task(configuration, outside_prerequisites,
            "Dump all data from #{store.name} for #{data_unit.name} from the current env",
            data_unit.name, store.name)
          define_restore_from_task(configuration, outside_prerequisites,
            "Restore all data into #{store.name} for #{data_unit.name} from the specified env into the current env",
            data_unit.name, store.name)
        end
      end
    end

    def create_runner(configuration)
      # TODO: externalize configuration
      ::Leda::Runner.new(configuration, Rails.env, Rails.root.join('db/leda'))
    end

    def define_dump_task(configuration, outside_prerequisites, description, data_unit_name, store_name)
      task_name = [data_unit_name, store_name, 'dump'].compact.join(':')

      t = ::Rake::Task.define_task(task_name => outside_prerequisites) do
        create_runner(configuration).dump(data_unit_name, store_name)
      end
      t.add_description description
    end

    def define_restore_from_task(configuration, outside_prerequisites, description, data_unit_name, store_name)
      task_name = [data_unit_name, store_name, 'restore_from'].compact.join(':')

      t = ::Rake::Task.define_task(task_name, [:source_env] => outside_prerequisites) do |t, args|
        source_env = args[:source_env] or fail "Please specify the source env name"

        create_runner(configuration).restore_from(source_env, data_unit_name, store_name)
      end
      t.add_description description
    end
  end
end
