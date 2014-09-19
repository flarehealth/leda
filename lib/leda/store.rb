require 'leda'
require 'active_support/core_ext/string/inflections'

module Leda
  ##
  # Mix-in for defining the set of data needed from a particular backing store
  # in a data unit. E.g., for a relational database it might be a set of tables.
  module Store
    attr_reader :options

    def initialize(options)
      @options = options.dup
    end

    def self.registered_stores
      @registered_stores ||= {}
    end

    def self.included(included_into)
      name = included_into.name.demodulize.underscore
      register_store(included_into, name)
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