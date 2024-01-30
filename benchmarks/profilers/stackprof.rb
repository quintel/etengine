# frozen_string_literal: true

class Benchmarks

  class Profiler

    class StackProf < Profiler::Base

      def profile(filename:, output_path:, mode: :cpu, &block)
        GC.disable

        ::StackProf.run(mode: mode || @mode, interval: 1000, raw: true, out: "#{output_path}/#{filename}.dump") do
          yield block
        end

        GC.enable
      end
    end
  end
end
