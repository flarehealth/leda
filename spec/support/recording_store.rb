class RecordingStore
  include Leda::Store

  def dump_directories
    @dump_directories ||= []
  end

  def restore_from_directories
    @restore_from_directories ||= []
  end

  def dump(directory)
    dump_directories << directory
  end

  def restore_from(directory)
    restore_from_directories << directory
  end
end

%w(mock_a mock_b mock_c).each do |mock_name|
  store = Class.new(RecordingStore)
  store.class_eval <<-DEF
    def name
      #{mock_name.inspect}
    end
  DEF
  Leda::Store.register_store(store, mock_name)
end
