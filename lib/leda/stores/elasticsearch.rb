require 'leda'

require 'oj'

module Leda
  module Stores
    class Elasticsearch
      include Leda::Store

      attr_reader :indices, :es_client

      def initialize(*)
        super

        @indices = options[:indices]
      end

      def dump(directory)
        Runner.new(directory, self).dump
      end

      def restore_from(directory)
        Runner.new(directory, self).restore
      end

      private

      def es_client
        # TODO: make this configuration externalizable
        ::Elasticsearch::Model.client
      end

      class Runner
        attr_reader :directory, :host

        def initialize(directory, host)
          @directory = directory
          @host = host
        end

        def dump
          $stderr.puts "Exporting to #{echo_fn(directory)} ..."
          indices.each do |index|
            dump_index_metadata(index)
            scan_all_records_into_bulk_format(index)
          end
          $stderr.puts "... export complete."
        end

        def restore
          $stderr.puts "Importing from #{echo_fn(directory)} ..."
          indices.each do |index|
            replace_index(index, directory)
            bulk_load_records(index, directory)
          end
          $stderr.puts "... import complete."
        end

        private

        def echo_fn(pathname)
          # TODO: an alternative
          pathname.relative_path_from(Rails.root)
        end

        def mapping_filename(index)
          directory.join("#{index}_mapping.json")
        end

        def settings_filename(index)
          directory.join("#{index}_settings.json")
        end

        def bulk_records_filename(index)
          directory.join("#{index}_bulk-records.json")
        end

        def dump_index_metadata(index)
          dump_mapping(index)
          dump_settings(index)
        end

        def dump_mapping(index)
          fn = mapping_filename(index)
          $stderr.puts "  - Dumping mapping for #{index} to #{echo_fn(fn)}"
          mapping = host.es_client.indices.get_mapping index: index
          fn.open('w') { |f| f.puts JSON.pretty_generate(mapping) }
        end

        def dump_settings(index)
          fn = settings_filename(index)
          $stderr.puts "  - Dumping settings for #{index} to #{echo_fn(fn)}"
          settings = host.es_client.indices.get_settings index: index
          fn.open('w') { |f| f.puts JSON.pretty_generate(settings) }
        end

        def scan_all_records_into_bulk_format(index)
          fn = bulk_records_filename(index)
          $stderr.puts "  - Dumping records for #{index} to #{echo_fn(fn)} "

          # start the scroll with a search
          results = host.es_client.search index: index, search_type: 'scan', scroll: '5m', size: 500
          total_ct = results['hits']['total']

          written_ct = 0
          fn.open('w:utf-8') do |f|
            while results = host.es_client.scroll(scroll_id: results['_scroll_id'], scroll: '5m') and not results['hits']['hits'].empty?
              results['hits']['hits'].each do |hit|
                f.puts convert_to_bulk_index_rows(hit)
              end
              written_ct += results['hits']['hits'].size
              $stderr.print "\r    #{written_ct} / #{total_ct} => %5.1f%% done" % (written_ct * 100.0 / total_ct)
            end
          end
          $stderr.puts "\r     #{written_ct} / #{total_ct} =>  all done."
        end

        def convert_to_bulk_index_rows(hit)
          [
            Oj.dump({ "index" => hit.slice("_index", "_type", "_id") }),
            Oj.dump(hit['_source'])
          ]
        end

        def replace_index(index, source_env)
          map_fn = mapping_filename(index, source_env)
          $stderr.puts "  - Reading mapping from #{echo_fn(map_fn)}"
          mappings = Oj.load(map_fn.read).values.first # assume only one index

          set_fn = settings_filename(index, source_env)
          $stderr.puts "  - Reading settings from #{echo_fn(set_fn)}"
          settings = Oj.load(set_fn.read).values.first # assume only one index

          body = {}.merge!(mappings).merge!(settings)

          begin
            $stderr.print "  - Deleting index #{index} ... "
            host.es_client.indices.delete index: index
            $stderr.puts "done"
          rescue ::Elasticsearch::Transport::Transport::Errors::NotFound
            $stderr.puts "not necessary"
          end

          $stderr.puts "  - Creating index #{index} using settings and mapping from #{source_env}"
          host.es_client.indices.create index: index, body: body
        end

        RESTORE_BATCH_DISPATCH_TRIGGER=(1 << 19) # Stay below 1MB per request
        # N.b.: Assumption that each bulk op is two lines. This is true
        # so long as they are all index ops.
        BULK_LINES_PER_RECORD=2

        def bulk_load_records(index, source_env)
          fn = bulk_records_filename(index, source_env)
          $stderr.puts "  - Reading records for #{index} from #{echo_fn(fn)} "

          total_ct = 0
          fn.each_line { |l| total_ct += 1 }
          total_ct /= BULK_LINES_PER_RECORD

          batch = ""
          batch_line_ct = 0
          loaded_ct = 0
          fn.each_line do |line|
            batch_line_ct += 1
            batch << line
            if batch_line_ct % BULK_LINES_PER_RECORD == 0 && batch.size > RESTORE_BATCH_DISPATCH_TRIGGER
              bulk_load_batch(batch)
              loaded_ct += batch_line_ct / BULK_LINES_PER_RECORD
              $stderr.print "\r    #{loaded_ct} / #{total_ct} => %5.1f%% done" % (loaded_ct * 100.0 / total_ct)
              batch = ""
              batch_line_ct = 0
            end
          end
          unless batch.empty?
            bulk_load_batch(batch)
            loaded_ct += batch_line_ct / BULK_LINES_PER_RECORD
          end
          $stderr.puts "\r     #{loaded_ct} / #{total_ct} =>  all done."
        end

        def bulk_load_batch(batch)
          host.es_client.bulk body: batch
        end

      end
    end
  end
end
