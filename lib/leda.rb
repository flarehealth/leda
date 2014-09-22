require "leda/version"

module Leda
  autoload :Capistrano, 'leda/capistrano'
  autoload :Configuration, 'leda/configuration'
  autoload :DataUnit, 'leda/data_unit'
  autoload :Rake, 'leda/rake'
  autoload :Runner, 'leda/runner'
  autoload :Store, 'leda/store'

  class << self
    def configuration
      @configuration || reset_configuration
    end

    def reset_configuration
      @configuration = ::Leda::Configuration.new
    end

    ##
    # Builds up the global Leda configuration using the configuration DSL.
    #
    # Multiple invocations will add to the existing configuration. Call
    # {#reset_configuration} to clear if desired.
    def configure(&dsl)
      configuration.update(&dsl)
    end

    def define_rake_tasks(*prerequisites)
      ::Leda::Rake.define_tasks(configuration, prerequisites)
    end

    def define_capistrano_tasks(rake_task_namespace)
      ::Leda::Capistrano.define_tasks(configuration, rake_task_namespace)
    end
  end
end
