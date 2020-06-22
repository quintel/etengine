module Gql::Runtime
  # ATTENTION: use :: namespace
  # Rubel::Base inherits from BasicObject. This means we don't have
  # access to the default namespace, so prepend classes and modules
  # with ::.
  class Debug < Rubel::Runtime::Console

    attr_reader :scope

    def initialize(scope = nil)
      @scope = scope
    end

    def logger
      scope.graph.logger
    end

    def log(key, attr_name, options = {}, &block)
      type = options.fetch(:type, :gql)
      if block_given?
        logger.log(type, key, attr_name, nil, options, &block)
      else
        logger.log(type, key, attr_name, nil, options)
      end
    end

    include ::Gql::Runtime::Functions::Legacy
    include ::Gql::Runtime::Functions::Constants
    include ::Gql::Runtime::Functions::Traversal
    include ::Gql::Runtime::Functions::Aggregate
    include ::Gql::Runtime::Functions::Control
    include ::Gql::Runtime::Functions::Lookup
    include ::Gql::Runtime::Functions::Policy
    include ::Gql::Runtime::Functions::Update
    include ::Gql::Runtime::Functions::Helper
    include ::Gql::Runtime::Functions::Core

    module FunctionDebug

      # @private
      def update_element_with(object, attribute_name, value)
        obj_key = object.key rescue nil
        log("UPDATE", "#{scope.input_key}: #{obj_key}.#{attribute_name} =", :type => :update) do
          super
        end
      end

      def NORMCDF(*args)
        log("NORMCDF", "NORMCDF") do
          super
        end
      end

      def Q(key)
        log("Q", "Q: #{key}", :gquery_key => key) do
          super
        end
      end

      def GREATER(*args)
        log("GREATER", "GREATER: #{args.join(' ')}") do
          super
        end
      end

      def M(elements, attr_name)
        log("MAP: #{attr_name}", "MAP: #{attr_name}") do
          super
        end
      end

      def SQRT(*args)
        log("SQRT", "SQRT") do
          super
        end
      end

      def PRODUCT(*args)
        log("PRODUCT", "PRODUCT") do
          super
        end
      end

      def SUM(*args)
        log("SUM", "SUM") do
          super
        end
      end

      def GET(element, attr_name)
        key = element.key rescue nil
        log("MAP/GET: #{key}", "MAP/GET: #{key}", {:node => key}) do
          super
        end
      end

      def G(key)
        log("GROUP: #{key}", "GROUP: #{key}") do
          super
        end
      end
    end

    include FunctionDebug
  end
end
