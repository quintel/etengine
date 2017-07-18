module Qernel::Plugins
  # Mixed into a class provides helper and DSL methods so that the class may be
  # used by the Graph Lifecycle as an optional, runtime plugin.
  module Plugin
    extend ActiveSupport::Concern

    included do
      class_attribute :hooks
      self.hooks = Hash.new { |hash, key| hash[key] = [] }
    end

    # Public: Creates a new plugin instance, assigning the graph.
    def initialize(graph)
      @graph = graph
    end

    # Public: Triggers execution of a callback on the plugin.
    #
    # side  - :before, or :after.
    # event - The name of the callback triggered by the Lifecycle, such as
    #         "calculation", "first_calculation", etc.
    # *args - Optional extra arguments given to the callback method.
    #
    # Returns nothing.
    def trigger(side, event, *args)
      self.class.hooks[:"#{ side }_#{ event }"].each do |method_name|
        if method(method_name).arity.zero?
          __send__(method_name)
        else
          __send__(method_name, *args)
        end
      end

      nil
    end

    # Public: A human-readable version of the plugin for debugging.
    def inspect
      "#<#{ self.class.name }>"
    end

    module ClassMethods
      # Public: Adds a new "before" hook to the plugin.
      #
      # event    - The name of the callback triggered by the Lifecycle, such as
      #            "calculation", "first_calculation", etc.
      # callback - The name of the method to be triggered on the plugin before
      #            the event occurs.
      #
      # For example:
      #   before :calculation, :load_extra_data
      #
      # Returns nothing.
      def before(event, callback)
        install_hook(:before, event, callback)
      end

      # Public: Adds a new "after" hook to the plugin.
      #
      # event    - The name of the callback triggered by the Lifecycle, such as
      #            "calculation", "first_calculation", etc.
      # callback - The name of the method to be triggered on the plugin after
      #            the event occurs.
      #
      # For example:
      #   after :calculation, :post_process_data
      #
      # Returns nothing.
      def after(event, callback)
        install_hook(:after, event, callback)
      end

      # Internal: Sets up inheritance of hooks, ensuring that subclasses cannot
      # affect the hooks defined on the superclass.
      def inherited(child)
        child.hooks = Hash[self.hooks.map { |key, hook| [key, hook.dup] }]
        child.hooks.default_proc = proc { |hash, key| hash[key] = [] }
      end

      # Internal: Used to identify the plugin.
      def plugin_name
        name.split('::').last.underscore.to_sym
      end

      # Internal: Is the plugin enabled? By default, all are.
      def enabled?(*)
        true
      end

      #######
      private
      #######

      # Internal: Adds a new before or after hook.
      def install_hook(side, event, callback)
        self.hooks[:"#{ side }_#{ event }"].push(callback)
      end
    end # ClassMethods
  end # Plugin
end # Qernel::Plugins
