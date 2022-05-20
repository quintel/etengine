# Creates JSON with the data necessary to run the merit order externally.
#
# The JSON contains two keys: "profiles" and "participants". The latter
# contains an array of hashes describing each producer which may be
# included. Instead of duplicating the load profiles, each participant
# specifies a "key" specifying the profile to use from the "profiles" hash.
#
# For example:
#
#   {
#     "profiles": { "profile_1": [1, 2, ...] },
#     "participants": [
#       { "key": "parti_1", "profile": "profile_1" },
#       { "key": "parti_2", "profile": "profile_1" },
#     ]
#   }
class MeritConfigSerializer
  # Keys which should be included for each participant.
  DISPATCHABLE_KEYS = %w(
    key marginal_costs output_capacity_per_unit number_of_units
    availability fixed_costs_per_unit fixed_om_costs_per_unit
  ).map(&:to_sym).freeze

  # TODO: how will we handle the new cost calculations?
  FLEX_KEYS = %i[
    key marginal_costs input_capacity_per_unit output_capacity_per_unit
    number_of_units
  ].freeze

  USER_KEYS = %i[
    key
  ]

  # Public: Creates a new serializer. Requires a copy of the Qernel::Graph
  # from which it can retrieve information about each participant. Typically
  # this should be the "future" graph.
  def initialize(graph)
    @graph = graph
  end

  # Public: Creates a hash with the merit order data.
  def as_json(*)
    @manager = Qernel::MeritFacade::Manager.new(@graph)
    data  = { profiles: {}, participants: [] }
    area  = Atlas::Dataset.find(@graph.area.area_code)

    # TODO: refactor these three in something more generic
    @manager.order.participants.producers.each do |producer|
      data[:participants].push(participant_data(producer)) if include_participant?(producer)
    end.compact

    # TODO: add interconnector price curves if there is one
    @manager.order.participants.flex.each do |flex|
      data[:participants].push(participant_data(flex)) if include_participant?(flex)
    end.compact

    @manager.order.participants.users.each do |user|
      data[:participants].push(participant_data(user)) if include_user?(user)
    end

    data[:participants].pluck(:profile).uniq.compact.each do |profile_key|
      next unless profile_key

      participant, profile = profile_key.split('.', 2)

      data[:profiles][profile_key] ||=
        if participant && profile # dynamic curve
          @manager.curves.curve(profile, @graph.node(participant).node_api).to_a
        else
          area.load_profile(profile_key).to_a
        end
    end

    data
  end

  private

  def participant_data(participant)
    data = {
      profile:  profile_key(participant),
      type:     participant_type(participant)
    }

    attribute_keys(data).each_with_object(data) do |key, hash|
      hash[key] =
        if key == :total_consumption
          @manager.adapters[participant.key].input_of_carrier
        else
          format_value(participant.public_send(key))
        end
    end
  end

  def profile_key(participant)
    key = load_profile_key(participant)
    key&.start_with?('dynamic', 'weather', 'fever') ? "#{participant.key}.#{key}" : key
  end

  def load_profile_key(participant)
    @graph.node(participant.key).node_api.load_profile_key
  end

  def participant_type(participant)
    participant.class.name.split('::').last
      .underscore.sub(/_producer\z/, ''.freeze).sub(/base\z/, 'generic'.freeze)
  end

  def attribute_keys(data)
    if data[:type] == 'generic'
      FLEX_KEYS
    elsif data[:type] == 'storage'
      FLEX_KEYS + [:volume_per_unit]
    elsif data[:type] == 'total_consumption'
      USER_KEYS + [:total_consumption]
    elsif data[:type] == 'with_curve'
      USER_KEYS + [:load_curve]
    elsif data[:type] == 'consumption_loss'
      USER_KEYS + [:consumption_share]
    elsif data[:profile].present?
      DISPATCHABLE_KEYS + [:full_load_hours]
    else
      DISPATCHABLE_KEYS
    end
  end

  def include_participant?(participant)
    return false unless participant.number_of_units.positive?
    return false if participant.is_a?(Merit::Flex::BlackHole)

    true
  end

  # TODO: specify which users should be included
  def include_user?(user)
    true
  end

  def format_value(value)
    value.is_a?(Numeric) && value.to_f == Float::INFINITY ? 0.0 : value
  end
end
