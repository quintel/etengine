# frozen_string_literal: true

class Benchmarks

  class Profiler

    class Base
      attr_reader :result

      def initialize(mode: :cpu)
        @mode = mode
        @result = nil
      end

      def profile; end # Descendants: please implement!
    end
  end
end
