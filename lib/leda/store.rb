require 'leda'
require 'active_support/core_ext/string/inflections'

module Leda
  ##
  # Mix-in for defining the set of data needed from a particular backing store
  # in a data unit. E.g., for a relational database it might be a set of tables.
  #
  # A store must define the following methods:
  #
  #   # Dump the configured data to the specified directory
  #   # @param [Pathname]
  #   def dump(directory); end
  #
  #   # Restore from the data found in the given directory
  #   # @param [Pathname]
  #   def restore_from(directory); end
  module Store
    attr_reader :options

    def initialize(options={})
      @options = options.dup
    end

    def name
      self.class.default_name(self.class)
    end

    def self.default_name(clazz)
      clazz.name.demodulize.underscore
    end

    def self.registered_stores
      @registered_stores ||= {}
    end

    def self.included(included_into)
      register_store(included_into, default_name(included_into))
    end

    def self.register_store(store_class, name)
      registered_stores[name.to_s] = store_class
    end

    def self.find(store_name)
      registered_stores[store_name.to_s]
    end
  end
end

# XXX: temporary
require 'leda/stores/postgresql'
require 'leda/stores/elasticsearch'
