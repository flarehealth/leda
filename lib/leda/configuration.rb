require 'leda'

require 'pathname'

module Leda
  class Configuration
    attr_reader :base_path

    def initialize(&dsl)
      @data_units_map = {}
      @base_path = Pathname.new('db/leda')

      if block_given?
        update(&dsl)
      end
    end

    def update(&dsl)
      dsl.call(self)
      self
    end

    def data_unit(name, &dsl)
      data_unit = (@data_units_map[name] ||= DataUnit.new(name))

      if block_given?
        dsl.call(DataUnitConfigurator.new(data_unit))
      end

      data_unit
    end

    def data_units
      @data_units_map.values
    end

    def project_root_dir
      @project_root_dir or fail "Please set project_root_dir in your Leda configuration"
    end

    def project_root_dir=(path)
      @project_root_dir = ensure_pathname(path)
    end

    def base_path=(path)
      @base_path = ensure_pathname(path)
    end

    def base_dir
      project_root_dir + base_path
    end

    private

    def ensure_pathname(path)
      case path
      when Pathname
        path
      when nil
        nil
      else
        Pathname.new(path.to_s)
      end
    end

    ##
    # @private
    class DataUnitConfigurator
      attr_reader :target

      def initialize(data_unit)
        @target = data_unit
      end

      def add_store(store_class, options)
        options ||= {}

        target.stores << store_class.new(options)
      end

      def method_missing(name, *args)
        store_class = Store.find(name)
        if store_class
          add_store(store_class, args.first)
        else
          super
        end
      end
    end
  end
end
