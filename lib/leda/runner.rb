require 'leda'

module Leda
  ##
  # Actually runs a dump or restore using the store info in a {{Configuration}}.
  class Runner
    attr_reader :current_env, :configuration

    def initialize(current_env, configuration)
      @current_env = current_env
      @configuration = configuration
    end

    def directory(env, data_unit=nil, store=nil)
      p = configuration.base_dir.join(env)
      p = p.join(data_unit.name) if data_unit
      p = p.join(store.name) if store
      p
    end

    def relative_directory(env, data_unit=nil, store=nil)
      directory(@current_env, data_unit, store).
        relative_path_from(configuration.project_root_dir)
    end

    ##
    # Performs dumps for the configured stores. Can optionally be limited to
    # one data unit and/or store type.
    def dump(data_unit_name=nil, store_name=nil)
      each_data_unit_store(data_unit_name, store_name).each do |data_unit, store|
        dir = directory(@current_env, data_unit, store)
        dir.mkpath
        store.dump(dir)
      end
    end

    def dump_relative_paths(data_unit_name=nil, store_name=nil)
      each_data_unit_store(data_unit_name, store_name).flat_map do |data_unit, store|
        relative_directory(@current_env, data_unit, store)
      end
    end

    ##
    # Performs restores for the configured stores. Can optionally be limited to
    # one data unit and/or store type.
    def restore_from(source_env, data_unit_name=nil, store_name=nil)
      each_data_unit_store(data_unit_name, store_name).each do |data_unit, store|
        store.restore_from(directory(source_env, data_unit, store))
      end
    end

    private

    def each_data_unit_store(data_unit_name=nil, store_name=nil)
      Enumerator.new do |y|
        yielded_any = false
        configuration.data_units.each do |du|
          if data_unit_name.nil? || du.name == data_unit_name
            du.stores.each do |store|
              if store_name.nil? || store.name == store_name
                yielded_any = true
                y << [du, store]
              end
            end
          end
        end
        fail "No data configured that matches #{[data_unit_name, store_name].compact.join(':')}" unless yielded_any
      end
    end
  end
end
