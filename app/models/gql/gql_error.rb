module Gql

  class GqlError < StandardError
    def initialize(message = nil)
      super(message)
    end
  end

  # A "wrapper" exception which contains another exception raised during
  # execution of a Gql::Command.
  class CommandError < GqlError
    extend Forwardable

    # Methods not to be delegated back to the original exception.
    NO_DELEGATE = [*Object.methods, :exception, :set_backtrace]

    # Delegate everything else back to the original exception.
    (GqlError.public_instance_methods - NO_DELEGATE).each do |meth|
      def_delegator(:@original, meth)
    end

    # Public: Creates a new CommandError.
    #
    # command  - The command which failed to execute.
    # original - The original exception which was raised when executing the
    #            command.
    #
    # Returns a CommandError.
    def initialize(command, original)
      @command  = command
      @original = original
    end

    # Public: An altered backtrace which swaps out (eval) lines (Procs executed
    # by Rubel) for the name of the command which was executed.
    #
    # Returns an array of strings.
    def backtrace
      trace = @original.backtrace.dup

      index  = trace.index { |line| line.start_with?('(eval)') }
      lineno = trace[index].match(/^\(eval\):(\d+)/)[1].to_i

      trace[index] = @command.exception_trace(lineno)

      trace
    end
  end

  class NoSuchInputError < GqlError
    def initialize(key)
      super "No input exists with the key #{ key.inspect }"
    end
  end

end
