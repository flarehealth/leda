module Leda
  module Capistrano
    extend self

    ##
    # Defines capstrano tasks which run a dump remotely, compress it, download
    # it, and expand it locally.
    #
    # As with {{Rake.define_tasks}}, it's probably best to run this inside a
    # namespace.
    def define_tasks(configuration, rake_task_namespace='data')
      configuration.data_units.each do |data_unit|
        t = ::Rake::Task.define_task [data_unit.name, 'dump'].join(':') do
          current_env = fetch(:stage).to_s
          runner = Runner.new(current_env, configuration)
          tarball_directory = runner.relative_directory(current_env, data_unit)
          tarball_path = tarball_directory.to_s + ".tar.bz2"
          paths = runner.dump_relative_paths(data_unit.name)

          # Create local target directory
          run_locally do
            execute :mkdir, '-p', tarball_directory.to_s
          end

          # dump & compress on server
          on roles(:app) do
            within(current_path) do
              execute :rake, [rake_task_namespace, data_unit.name, 'dump'].compact.join(':')
              execute :tar, 'cjvf', tarball_path, paths

              expected_remote_filename = "#{current_path}/#{tarball_path}"
              download! expected_remote_filename, tarball_path

              execute :rm, tarball_path
            end
          end

          # decompress locally
          run_locally do
            execute :tar, 'xjvf', tarball_path
          end
        end
        t.add_description "Dump & download the remote #{data_unit.name} data"
      end

      t = ::Rake::Task.define_task 'dump' => configuration.data_units.map { |du| [rake_task_namespace, du.name, 'dump'].compact.join(':') }
      t.add_description "Dump and download all remote data units"
    end
  end
end

__END__

namespace :data do
  def execute_remote_dump(key, data_types)
    paths_in_project = data_types.map { |ext| "db/data/#{key}.#{fetch :stage}.#{ext}" }
    tarball_path = "db/data/#{key}.#{fetch :stage}.tar.bz2"

    on roles(:app) do
      within(current_path) do
        execute :rake, "data:#{key}:dump"
        execute :tar, 'cjvf', tarball_path, paths_in_project

        expected_remote_filename = "#{current_path}/#{tarball_path}"
        download! expected_remote_filename, tarball_path

        execute :rm, tarball_path
      end
    end

    # decompress locally
    sh 'tar', 'xjvf', tarball_path
  end

  {
    providers: %w(psql elasticsearch),
    groups: %w(psql)
  }.each do |key, data_types|
    desc "Dump & download the remote #{key} data"
    task "#{key}:dump" do
      execute_remote_dump(key, data_types)
    end
  end
end
