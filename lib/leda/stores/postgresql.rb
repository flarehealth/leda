require 'leda'

require 'tempfile'
require 'shellwords'

module Leda
  module Stores
    ##
    # Store for PostgreSQL. Uses PG command line utilties to dump and restore.
    #
    # Options:
    #
    # * `:tables`. An array of table names to dump/restore. The tables will be
    #   restored in the order given in the array.
    class Postgresql
      include Leda::Store

      attr_reader :tables

      def initialize(*args)
        super

        @tables = options[:tables]
        @filter_executable = options[:filter]
      end

      def filename(directory)
        directory.join('dump.psql')
      end

      def dump(directory)
        pgenv

        fn = filename(directory).to_s
        $stderr.puts "Exporting to #{fn} ..."
        dump_cmd = (['pg_dump', '-a', '-Fp', '-O', '-x'] + tables.flat_map { |t| ['-t', t] }).shelljoin

        # TODO:
        filter_cmd = nil
        if @filter_executable
          filter_cmd = "| #{@filter_executable}"
        end

        out_cmd = "> " + [fn].shelljoin
        if system([dump_cmd, filter_cmd, out_cmd].compact.join(' '))
          $stderr.puts "... export complete."
        else
          fail "Export failed."
        end
      end

      def restore_from(directory)
        pgenv

        source_file = filename(directory)

        unless source_file.exist?
          fail "Expected provider dump not found: #{source_file}"
        end

        begin
          $stderr.puts "Importing from #{source_file}"
          open('|psql -aq', 'w') do |psql|
            psql.puts '\set ON_ERROR_STOP'
            psql.puts "BEGIN;"
            psql.puts "TRUNCATE #{tables.join(', ')} CASCADE;"
            psql.puts source_file.read
            psql.puts "COMMIT;"
          end
        rescue Errno::EPIPE => e
          $stderr.puts "psql terminated early; check above for a reason"
        end
      end

      private

      def database_config
        # TODO: make this agnostic
        @database_config ||= ActiveRecord::Base.configurations[Rails.env].reverse_merge(
          'host' => 'localhost'
        )
      end

      ##
      # Sets the libpq environment variables based on the current AR database config.
      def pgenv
        pgenv_values.each do |env_var, value|
          ENV[env_var] = value.to_s if value
        end
        ENV['PGPASSFILE'] = temporary_pgpassfile
      end

      ##
      # Computes, but does not set into the environment, the libpq env vars implied
      # by the given AR-style config hash. Does not include the password, since
      # there is no libpq value for the password.
      def pgenv_values
        @pgenv_values ||=
          {
            'host' => 'PGHOST',
            'port' => 'PGPORT',
            'username' => 'PGUSER',
            'database' => 'PGDATABASE',
          }.each_with_object({}) do |(param_name, env_var), values|
            values[env_var] = database_config[param_name] if database_config[param_name]
          end
      end

      ##
      # Creates a temporary pgpass file based on the given AR-style config hash.
      # Returns the path to the file. This file will be automatically deleted when
      # the interpreter shuts down, so don't share the path outside of the process
      # and its children.
      def temporary_pgpassfile
        return @temporary_pgpassfile.path if @temporary_pgpassfile

        pass = database_config['password']

        # Tempfile.open does not return the tempfile
        begin
          # must maintain a reference to the tempfile object so that it doesn't
          # get deleted until we're done with it.
          @temporary_pgpassfile = Tempfile.open('dc')
          @temporary_pgpassfile.chmod(0600)
          @temporary_pgpassfile.puts [pgenv_values['PGHOST'], pgenv_values['PGPORT'] || '*', pgenv_values['PGDATABASE'], pgenv_values['PGUSER'], pass].join(':')
        ensure
          @temporary_pgpassfile.close
        end

        @temporary_pgpassfile.path
      end
    end
  end
end
