# frozen_string_literal: true

# Creates JSON with the data necessary to run the merit order externally.
#
# The JSON contains two keys: "curves" and "participants". The latter
# contains an array of hashes describing each producer which may be
# included. Instead of duplicating the load curves, each participant
# specifies a "key" specifying the profile to use from the "curves" hash.
#
# For example:
#
#   {
#     "curves": { "curve_1": [1, 2, ...] },
#     "participants": [
#       { "key": "parti_1", "curve": "curve_1" },
#       { "key": "parti_2", "curve": "curve_1" },
#     ]
#   }
class MeritConfigSerializer
  # Keys which should be included for each participant.
  DISPATCHABLE_KEYS = %i[
    key marginal_costs output_capacity_per_unit number_of_units
    availability fixed_costs_per_unit fixed_om_costs_per_unit
  ].freeze

  FLEX_KEYS = %i[
    key marginal_costs input_capacity_per_unit output_capacity_per_unit
    number_of_units
  ].freeze

  STORAGE_KEYS = %i[
    volume_per_unit input_efficiency output_efficiency reserve_class decay
  ].freeze

  USER_KEYS = %i[
    key
  ].freeze

  # Public: Creates a new serializer. Requires a copy of the Qernel::Graph
  # from which it can retrieve information about each participant. Typically
  # this should be the "future" graph.
  def initialize(graph, include_curves: true)
    @graph = graph
    @include_curves = include_curves
  end

  # Public: Creates a hash with the merit order data.
  def as_json(*)
    @manager = Qernel::MeritFacade::Manager.new(@graph)
    @area = Atlas::Dataset.find(@graph.area.area_code)

    data = @include_curves ? { curves: {}, participants: [] } : { participants: [] }

    # Add participant data
    participants.each do |participant|
      data[:participants].push(participant_data(participant)) if include_participant?(participant)
    end.compact

    # Add curves
    add_curve_data_to(data) if @include_curves

    data
  end

  private

  # Internal: All elegible participants from Merit
  def participants
    @manager.order.participants.producers + @manager.order.participants.flex +
      @manager.order.participants.users
  end

  def participant_data(participant)
    data = { type: participant_type(participant) }
    data[:curve] = curve_key(participant) if @include_curves

    attribute_keys(data).each_with_object(data) do |key, hash|
      hash[key] =
        if key == :total_consumption
          @manager.adapters[participant.key].input_of_carrier
        elsif participant.respond_to?(key)
          value_for(participant, key)
        end
    end
  end

  def value_for(participant, key)
    format_value(participant.public_send(key))
  rescue NoMethodError
    nil
  end

  # Internal: Returns the key of the curve that should accompany the participant. Multiple
  # participants can have the same key. Most curves are load profiles, but for interconnectors
  # the price curve is used.
  #
  # Returns the curve key
  def curve_key(participant)
    if participant.key.to_s.include?('interconnector')
      interconnector_price_curve_key(participant)
    elsif participant.key.to_s.end_with?('consumer', 'producer')
      "#{participant.key}.load_curve"
    else
      key = load_profile_key(participant)
      key&.start_with?('dynamic', 'weather', 'fever') ? "#{participant.key}.#{key}" : key
    end
  end

  def load_profile_key(participant)
    node(participant.key).node_api.load_profile_key
  end

  def interconnector_price_curve_key(participant)
    return if node(participant.key).node_api.marginal_cost_curve.empty?

    "#{participant.key}.marginal_cost_curve"
  end

  # Internal: Returns the associated node
  # If the participant does not have a node (for example it is some kind of subtype like '_consumer'
  # or '_producer' as for OptimizingStorage) the last word is removed from the key and checked
  # again.
  def node(participant_key)
    @graph.node(participant_key) ||
      @graph.node(participant_key.to_s.sub(/_[^_]*$/, '')) ||
      raise("No such node: #{participant_key}")
  end

  # Internal: Finds the participant again based on its key by looking at the adapters
  # Only used for finding the '_consumer' or '_producer' participants for storage optimization
  def participant_from(key)
    adapter = @manager.adapters[key.to_s.sub(/_[^_]*$/, '').to_sym]
    if adapter&.participant.is_a?(Array)
      key.end_with?('producer') ? adapter.participant[0] : adapter.participant[1]
    end
  end

  # Internal: Adds the curve data to the data object
  # The data object should already be populated with participants and their
  # curve keys
  def add_curve_data_to(data)
    data[:participants].pluck(:curve).uniq.compact.each do |joined_curve_key|
      next unless joined_curve_key

      data[:curves][joined_curve_key] ||= curve_data(joined_curve_key)
    end
  end

  # Internal: splits the joined participant.curve key if possible, and determines the way on how
  # to access the curve data. For dynamic, fever and weather curves, the MeritFacadeManagers
  # curveset is used. The interconnectors use the general node API, and the standard curves
  # come directly from the area.
  #
  # Returns the curve as an array
  def curve_data(joined_key)
    participant_key, curve_name = joined_key.split('.', 2)

    if curve_name == 'marginal_cost_curve' # interconnector
      node(participant_key).node_api.marginal_cost_curve
    elsif curve_name == 'load_curve' # optimizing_storage
      participant_from(participant_key)&.load_curve
    elsif participant_key && curve_name # dynamic curve
      @manager.curves.curve(curve_name, node(participant_key).node_api).to_a
    else
      @area.load_profile(joined_key).to_a
    end
  end

  def participant_type(participant)
    participant.class.name.split('::').last
      .underscore.sub(/_producer\z/, '').sub(/base\z/, 'generic')
  end

  def attribute_keys(data)
    if data[:type] == 'generic'
      FLEX_KEYS
    elsif data[:type] == 'storage'
      FLEX_KEYS + STORAGE_KEYS
    elsif data[:type] == 'total_consumption'
      USER_KEYS + [:total_consumption]
    elsif data[:type] == 'with_curve'
      USER_KEYS
    elsif data[:type] == 'consumption_loss'
      USER_KEYS + [:consumption_share]
    elsif data[:curve].present?
      DISPATCHABLE_KEYS + [:full_load_hours]
    else
      DISPATCHABLE_KEYS
    end
  end

  def include_participant?(participant)
    return true if participant.is_a?(Merit::User)
    return false unless participant.number_of_units.positive?
    return false if participant.is_a?(Merit::Flex::BlackHole)

    true
  end

  def format_value(value)
    value.is_a?(Numeric) && value.to_f == Float::INFINITY ? 0.0 : value
  end
end
