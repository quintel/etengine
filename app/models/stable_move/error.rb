# frozen_string_literal: true

module StableMove
  # Raised when an export or import refuses to run, with a message for whoever runs it. The tasks
  # print it after "Stopped: ", so it starts in lower case unless it starts with a name.
  class Error < StandardError
    LISTED = 100

    # Public: The first LISTED items as indented lines that fit 72 columns, ending with how many
    # more there are out of `total`.
    def self.listing(items, total = items.size)
      text = items.first(LISTED).join(', ')
      text += " and #{total - LISTED} more" if total > LISTED

      ActionController::Base.helpers.word_wrap(text, line_width: 67).lines(chomp: true)
        .each_with_index.map { |line, index| "#{index.zero? ? '   - ' : '     '}#{line}" }
    end
  end
end
