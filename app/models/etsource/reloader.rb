# Listen >=2.8 patch to silence duplicate directory errors.
#
# Error messages from Listen are due to symlinks within ETSource; we cannot
# resolve this without significant work in ETSource to eliminate symlinks.
#
# See https://github.com/guard/listen/wiki/Duplicate-directory-errors
module Listen
  class Record
    class SymlinkDetector
      def _fail(_, _)
        raise Error, "Don't watch locally-symlinked directory twice"
      end
    end
  end
end

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
    DIRS = %w[
      carriers
      config
      datasets
      gqueries
      graphs
      initializer_inputs
      inputs
      presets
    ].freeze

    # Directories which may be reloaded without throwing away the graph.
    RECORD_RELOAD = %w[
      gqueries
      inputs
      initializer_inputs
      presets
    ].freeze

    class << self
      def start!
        return true if @listener

        watched_dirs = DIRS.map(&Regexp.method(:escape)).join('|')

        @listener = Listen.to(ETSOURCE_EXPORT_DIR.to_s) do |(path, *)|
          path = Pathname.new(path).relative_path_from(Atlas.data_dir)
          type = path.to_s.split('/').first

          if RECORD_RELOAD.include?(type)
            reload_record!(type)
          else
            reload!
          end
        end

        @listener.only(%r{(?:#{ watched_dirs })/.*})
        @listener.start

        Rails.logger.info 'ETsource live reload: Listener started.'

        Kernel.at_exit { stop! }

        true
      end

      def stop!
        if @listener
          @listener.stop
          @listener = nil
        end
      end

      def reload_record!(type)
        class_name = type.classify

        "Atlas::#{class_name}".constantize.manager.clear!
        class_name.constantize.clear!
        Etsource::Loader.instance.clear!(type)

        Rails.logger.info "ETsource live reload: Cleared cache for #{type}."
      end

      def reload!(type = nil)
        Rails.cache.clear

        NastyCache.instance.expire!(
          keep_atlas_dataset: ! APP_CONFIG[:etsource_lazy_load_dataset])

        NastyCache.instance.expire_local!

        if type
          "Atlas::#{type.classify}".constantize.manager.clear!
        else
          Atlas::ActiveDocument::Manager.clear_all!
        end

        Rails.logger.info 'ETsource live reload: Caches cleared.'
      end
    end # class << self
  end # Reloader
end # Etsource
