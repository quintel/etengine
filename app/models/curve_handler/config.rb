# frozen_string_literal: true

module CurveHandler
  # Stores information about how to process an uploaded user curve.
  class Config
    # Public: Creates a new Config using a configuration hash from the ETSource YAML file. See
    # Etsource::Config.user_curves.
    def self.from_etsource(config_hash)
      key = config_hash.fetch(:key)
      handler_key = config_hash.fetch(:handler)

      if config_hash[:reduce]
        new(
          key,
          handler_key,
          config_hash[:reduce][:as],
          Array(config_hash[:reduce][:sets]).map(&:to_s)
        )
      else
        new(key, handler_key)
      end
    end

    attr_reader :key, :input_keys

    # Public: Creates a new Config.
    #
    # key         - A unique key for the uploaded curve.
    # handler_key - A symbol identifying what type of InputHandler is used by the curve.
    # reducer_key - An optional symbol identifying how to reduce the curve to a single value, which
    #               may then be used to set inputs.
    # input_keys  - An array of symbols, each matching the key of an input whose value will be set
    #               by the reducer.
    def initialize(key, handler_key, reducer_key = nil, input_keys = [])
      raise "Cannot create a #{self.class.name} without a key"     if key.nil?
      raise "Cannot create a #{self.class.name} without a handler" if handler_key.nil?

      @key = key
      @handler_key = handler_key.to_sym

      if reducer_key && input_keys.any?
        @reducer_key = reducer_key.to_sym
        @input_keys = input_keys
      else
        @reducer_key = nil
        @input_keys = []
      end
    end

    # Public: Returns the handler class specified by the config. Raises an error if the handler key
    # given does not match a known handler.
    def handler
      case @handler_key
      when :price
        Price
      when :generic
        Generic
      else
        raise "Unknown handler #{@handler_key.inspect} for user curve #{@key.inspect}"
      end
    end

    # Public: Returns the reudcer callable specified by the config. Raises an error if the reducer
    # given does not match a known handler.
    def reducer
      case @reducer_key
      when :full_load_hours
        Reducers::FullLoadHours
      when nil
        nil
      else
        raise "Unknown reducer #{@reducer_key.inspect} for user curve #{@key.inspect}"
      end
    end

    # Public: Returns whether the handler should set any input values for the scenario.
    def sets_inputs?
      @reducer_key && @input_keys.any? || false
    end

    # Public: Human-readable version of the Config for debugging.
    def inspect
      "#<#{self.class.name} #{@key} (#{@handler_key})>"
    end
  end
end
