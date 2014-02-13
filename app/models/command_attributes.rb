# Mixed into models which contain attributes which are GQL strings. Provides a
# useful helper for converting the string to a GQL::Command, including the extra
# information for getting a decent backtrace.
module CommandAttributes
  # Internal: Given an +attribute+ name, returns the GQL::Command which
  # represents the GQL string.
  #
  # Returns a GQL::Command.
  def command_for(attribute)
    cmd = Gql::Command.new(public_send(attribute))
    cmd.metadata.name = "#{ attribute } in #{ key }"

    if file_path
      cmd.metadata.file = file_path

      # Determine the line number on which the attribute is defined:
      lines  = file_path.read.lines
      lineno = lines.index { |line| line.match(/^- #{ attribute }/) } + 1

      # If it's a multi-line attribute, the query begins on the line
      # *following* the attribute name.
      lineno += 1 if lines[lineno - 1].match(/=\s*$/)

      cmd.metadata.offset = lineno
    end

    cmd
  end

  private :command_for
end # CommandAttributes
