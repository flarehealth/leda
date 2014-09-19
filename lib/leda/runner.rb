require 'leda'

module Leda
  ##
  # Actually runs a dump or restore using the store info in a {{Configuration}}.
  class Runner
    attr_reader :base_dir, :current_env, :configuration

    def initialize(base_dir, current_env, configuration)
      @base_dir = base_dir
      @current_env = current_env
      @configuration = configuration
    end

    def directory(env, data_unit_name, store_name)
      base_dir.join(env).join(data_unit_name).join(store_name)
    end

    ##
    # Performs dumps for the configured stores. Can optionally be limited to
    # one data unit and/or store type.
    def dump(data_unit_name=nil, store_name=nil)
      each_data_unit_store(data_unit_name, store_name).each do |data_unit, store|
        store.dump(directory(@current_env, data_unit.name, store.name))
      end
    end

    ##
    # Performs restores for the configured stores. Can optionally be limited to
    # one data unit and/or store type.
    def restore_from(source_env, data_unit_name=nil, store_name=nil)
      each_data_unit_store(data_unit_name, store_name).each do |data_unit, store|
        store.restore_from(directory(source_env, data_unit.name, store.name))
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
