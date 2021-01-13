# frozen_string_literal: true

module CurveHandler
  # Stores information about how to process an uploaded user curve.
  class Config
    delegate :serializer, to: :processor

    # Public: Retrieves a stored Config from ETSource, identified by the key.
    #
    # key       - A stringish key identifying the config to be loaded.
    # allow_nil - Boolean indicating whether it is acceptable to find no matching key.
    #
    # Returns a CurveHandler::Config. In the event that nil_ok=false and no matching Config is
    # found, KeyError is raised.
    def self.find(key, allow_nil: false)
      keyed = Etsource::Config.user_curves
      allow_nil ? keyed[key.to_s] : keyed.fetch(key.to_s)
    end

    # Public: Returns if the `key` matches a stored config.
    def self.key?(key)
      Etsource::Config.user_curves.key?(key.to_s)
    end

    # Public: Retrieves a stored Config from ETSource, identified by its db_key.
    #
    # key       - A stringish key identifying the config to be loaded.
    # allow_nil - Boolean indicating whether it is acceptable to find no matching db_key.
    #
    # Returns a CurveHandler::Config. In the event that nil_ok=false and no matching Config is
    # found, KeyError is raised.
    def self.find_by_db_key(key, allow_nil: false)
      keyed = Etsource::Config.user_curves.values.index_by(&:db_key)
      allow_nil ? keyed[key.to_s] : keyed.fetch(key.to_s)
    end

    # Public: Returns if the `key` matches a stored configs `db_key`.
    def self.db_key?(key)
      !find_by_db_key(key, allow_nil: true).nil?
    end

    # Public: Creates a new Config using a configuration hash from the ETSource YAML file. See
    # Etsource::Config.user_curves.
    def self.from_etsource(config_hash)
      key = config_hash.fetch(:key)
      processor_key = config_hash.fetch(:type)

      if config_hash[:reduce]
        new(
          key,
          processor_key,
          config_hash[:reduce][:as],
          Array(config_hash[:reduce][:sets]).map(&:to_s)
        )
      else
        new(key, processor_key)
      end
    end

    attr_reader :key, :input_keys, :processor_key

    # Public: Creates a new Config.
    #
    # key         - A unique key for the uploaded curve.
    # processor_key - A symbol identifying what type of InputHandler is used by the curve.
    # reducer_key - An optional symbol identifying how to reduce the curve to a single value, which
    #               may then be used to set inputs.
    # input_keys  - An array of symbols, each matching the key of an input whose value will be set
    #               by the reducer.
    def initialize(key, processor_key, reducer_key = nil, input_keys = [])
      raise "Cannot create a #{self.class.name} without a key"       if key.nil?
      raise "Cannot create a #{self.class.name} without a processor" if processor_key.nil?

      @key = key
      @processor_key = processor_key.to_sym

      if reducer_key && input_keys.any?
        @reducer_key = reducer_key.to_sym
        @input_keys = input_keys
      else
        @reducer_key = nil
        @input_keys = []
      end
    end

    # Public: The key used to store the file in the database.
    def db_key
      "#{@key}_curve"
    end

    # Public: Returns the processor class specified by the config. Raises an error if the processor
    # key given does not match a known processor.
    def processor
      case @processor_key
      when :generic
        Processors::Generic
      when :price
        Processors::Price
      when :profile
        Processors::Profile
      when :temperature
        Processors::Temperature
      else
        raise "Unknown processor #{@processor_key.inspect} for user curve #{@key.inspect}"
      end
    end

    # Public: Returns the reudcer callable specified by the config. Raises an error if the reducer
    # given does not match a known processor.
    def reducer
      case @reducer_key
      when :full_load_hours
        Reducers::FullLoadHours
      when :temperature
        Reducers::Temperature
      when nil
        nil
      else
        raise "Unknown reducer #{@reducer_key.inspect} for user curve #{@key.inspect}"
      end
    end

    # Public: Returns whether the processor should set any input values for the scenario.
    def sets_inputs?
      @reducer_key && @input_keys.any? || false
    end

    # Public: Human-readable version of the Config for debugging.
    def inspect
      "#<#{self.class.name} #{@key} (#{@processor_key})>"
    end
  end
end
