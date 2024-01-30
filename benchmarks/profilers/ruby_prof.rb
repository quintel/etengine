# frozen_string_literal: true

class Benchmarks

  class Profiler

    class RubyProf < Benchmarks::Profiler::Base

      def profile(filename:, output_path:, mode: nil, &block)
        # Disable Garbage Collection during profiling since RubyProf seems to get stuck in a loop
        # while keeping allocating memory and eventually crash with a core dump.
        GC.disable

        profile = ::RubyProf::Profile.new
        @result = profile.profile do
          yield block
        end
        @result.merge!

        store_result(filename, output_path)

        GC.enable
      end

      def store_result(filename:, output_path:)
        ensure_path_exists(store_output_path)

        printer = ::RubyProf::CallStackPrinter.new(@result)

        report_file = File.new("#{output_path}/#{filename}.html", 'w')
        printer.print(report_file, min_percent: 1)
        report_file.close
      end

      def ensure_path_exists(path)
        FileUtils.mkdir_p(path)
      end
    end
  end
end
