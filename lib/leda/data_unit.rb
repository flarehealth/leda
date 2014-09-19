require 'leda'

module Leda
  class DataUnit
    attr_reader :name
    attr_reader :stores

    def initialize(name)
      @name = name
      @stores = []
    end
  end
end
