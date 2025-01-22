module Gql
  # Represents a GQL statement which is to be executed. Optionally includes
  # metadata about where the GQL statement was defined which enabled better
  # error messages.
  class Command
    # Optional information about the command, used for enhancing error messages.
    #
    # name   - A name for identifying the command.
    # file   - A file in which the command, or +source+ is defined.
    # offset - The number of lines from the top of the +file+ on which the
    #          +source+ string is defined.
    Metadata = Struct.new(:name, :file, :offset)

    # Public: The original GQL statement as a string.
    attr_reader :source

    # Public: Creates a new command to be executed using the given +source+
    # statement.
    #
    # Returns a Command.
    def initialize(source)
      @source = clean(source)
    end

    # Public: Contains optional, additional information about the command.
    #
    # Returns a Command::Metadata.
    def metadata
      @md ||= Metadata.new(nil, nil, 1)
    end

    # Public: Converts the source statement to a proc for execution by Rubel.
    #
    # Returns a Proc.
    def to_proc
      @proc ||= Rubel.sanitized_proc(source)
    end

    # Public: Converts the command to a proc, and runs it with the given
    # arguments.
    #
    # Returns the result of running the command.
    def call(*args, &block)
      to_proc.call(*args, &block)
    end

    # Public: A human-readable version of the command.
    #
    # Returns a string.
    def inspect
      summary = truncate(source.gsub(/\n/, ' ').gsub(/\s+/, ' '))
      "#<#{ self.class.name } \"#{ summary }\">"
    end

    # Public: The command as a string; the source statement.
    #
    # Returns a string.
    def to_s
      source
    end

    # Public: A string with information about the command, should an exception
    # occur during execution. This will be inserted into the backtrace.
    #
    # Returns a string.
    def exception_trace(lineno)
      file  = metadata.file || '(anonymous query)'
      where = metadata.name || truncate(source)

      "#{ file }:#{ lineno + metadata.offset - 1 }: in `#{ where }'"
    end

    # Public: Creates a string summarising the original source statement, with
    # a highlight on the chosen +lineno+. +context+ controls how many lines
    # before and after the chosen line will be included.
    #
    # For example:
    #
    #   command.source_extract(50, 2)
    #   #    48: SUM(
    #   #    49:   1,
    #   # => 50:   SUM(2, '3'),
    #   #    51:   4
    #   #    52: )
    #
    # Returns a string.
    def source_extract(lineno, context = 5)
      lines   = @source.lines
      start   = [ 1, lineno - context ].max
      finish  = [ lineno + context, lines.length ].min
      padding = (metadata.offset + finish).to_s.length

      (start..finish).map do |number|
        indicator  = number == lineno ? ' => ' : '    '
        actual_num = (metadata.offset - 1 + number).to_s

        "#{ indicator }#{ actual_num.rjust(padding) }: #{ lines[number - 1] }"
      end.join
    end

    #######
    private
    #######

    # Internal: Truncates a +string+ to the desired +length+, appending "..." if
    # it is too long.
    def truncate(string, length = 40)
      string.length > (length - 3) ? "#{ string[0..length] }..." : string
    end

    # Internal: Removes extra "artifacts" from the source.
    def clean(string)
      cleaned = (string || '').dup

      cleaned.gsub!(/[\n\s\t]/, '')
      cleaned.gsub!(/^[a-z]+\:/,'')

      cleaned
    end
  end # Command
end # GQL
