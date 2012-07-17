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
    
    def log(key, attr_name, value, &block)
      if block_given?
        logger.log(:gql, key, attr_name, value, &block)
      else
        logger.log(:gql, key, attr_name, value)
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


      def NORMCDF(*args)
        log("NORMCDF", "NORMCDF", nil) do
          super
        end
      end

      def Q(key)
        log("Q", "Q: #{key}", nil) do
          super
        end
      end

      def GREATER(*args)
        log("GREATER", "GREATER: #{args.join(' ')}", nil) do
          super
        end
      end

      def M(elements, attr_name)
        log("MAP: #{attr_name}", "MAP: #{attr_name}", nil) do
          super
        end
      end

      def SQRT(*args)
        log("SQRT", "SQRT", nil) do
          super
        end
      end

      def PRODUCT(*args)
        log("PRODUCT", "PRODUCT", nil) do
          super
        end
      end

      def SUM(*args)
        log("SUM", "SUM", nil) do
          super
        end
      end

      def GET(element, attr_name)
        log("GET: #{element.key}", "GET: #{element.key}", nil) do
          super
        end
      end

      def G(key)
        log("GROUP: #{key}", "GROUP: #{key}", nil) do
          super
        end
      end
    end

    include FunctionDebug
  end
end