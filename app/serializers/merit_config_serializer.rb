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

  # Public: Creates a new serializer. Requires a copy of the Qernel::Graph
  # from which it can retrieve information about each participant. Typically
  # this should be the "future" graph.
  def initialize(graph)
    @graph = graph
  end

  # Public: Creates a hash with the merit order data.
  def as_json(*)
    manager = Qernel::MeritFacade::Manager.new(@graph)
    data  = { profiles: {}, participants: [] }
    area  = Atlas::Dataset.find(@graph.area.area_code)

    manager.order.participants.producers.each do |producer|
      if include_producer?(producer)
        data[:participants].push(participant_data(producer))
      end
    end.compact

    data[:participants].pluck(:profile).uniq.compact.each do |profile_key|
      next unless profile_key

      participant, profile = profile_key.split('-', 2)
      data[:profiles][profile_key] ||=
        if participant && profile # dynamic curve
          manager.curves.curve(profile, @graph.node(participant).node_api).to_a
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
      hash[key] = format_value(participant.public_send(key))
    end
  end

  def profile_key(participant)
    key = load_profile_key(participant)
    key&.start_with?('dynamic') ? "#{participant.key}-#{key}" : key
  end

  def load_profile_key(participant)
    @graph.node(participant.key).node_api.load_profile_key
  end

  def participant_type(participant)
    # TODO: make sure this is the Merit class name
    participant.class.name.split('::').last
      .underscore.sub(/_producer\z/, ''.freeze)
  end

  def attribute_keys(data)
    if data[:profile].present?
      DISPATCHABLE_KEYS + [:full_load_hours]
    else
      DISPATCHABLE_KEYS
    end
  end

  def include_producer?(producer)
    # TODO: check which flex producers we do want to have
    return false unless producer.number_of_units > 0
    return false if     producer.is_a?(Merit::Flex::Base)

    # Exclude import which has no profile.
    group = @graph.node(producer.key).dataset_get(:merit_order).group
    group ? group.to_sym != :import : true
  end

  def format_value(value)
    value.is_a?(Numeric) && value.to_f == Float::INFINITY ? 0.0 : value
  end
end
