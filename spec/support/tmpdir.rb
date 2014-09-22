require 'pathname'

module Leda::Spec
  module Tmpdir
    def spec_tmpdir(path=nil)
      @spec_tmpdir ||= Pathname.new(File.expand_path("../../spec/tmp", __FILE__))
      full = path ? @spec_tmpdir.join(path) : @spec_tmpdir
      full.mkpath
      full
    end

    def rm_tmpdir
      if @spec_tempdir
        @spec_tempdir.rmtree
      end
    end
  end
end
