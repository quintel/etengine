module Etsource
  # Watches for changes to ETsource files. Changes made to dataset, gquery,
  # input, or topology files will clear out the caches, forcing these files to
  # be reloaded upon the next request.
  #
  # Works only on the current process, and is only available in the
  # development environment.
  #
  # @example
  #   Etsource::Reloader.start!
  #
  class Reloader
    class << self
      def start!
        return true if @listener

        @listener = Listen.to(ETSOURCE_EXPORT_DIR)
        @listener.filter(%r{(?:datasets|gqueries|inputs|topology)/.*})
        @listener.change { |*| reload! }
        @listener.start(false)

        Rails.logger.info 'ETsource live reload: Listener started.'

        true
      end

      def reload!
        Rails.cache.clear
        NastyCache.instance.expire!

        Rails.logger.info 'ETsource live reload: Caches cleared.'
      end
    end # class << self
  end # Reloader
end # Etsource
