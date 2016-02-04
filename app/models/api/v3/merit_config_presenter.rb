module Api
  module V3
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
    class MeritConfigPresenter
      # Keys which should be included for each participant.
      DISPATCHABLE_KEYS = %w(
        key marginal_costs output_capacity_per_unit number_of_units
        availability fixed_costs_per_unit fixed_om_costs_per_unit
      ).map(&:to_sym).freeze

      # Public: Creates a new presenter. Requires a copy of the Qernel::Graph
      # from which it can retrieve information about each participant. Typically
      # this should be the "future" graph.
      def initialize(graph)
        @graph = graph
      end

      # Public: Creates a hash with the merit order data.
      def as_json(*)
        order = Qernel::Plugins::MeritOrder.new(@graph).order
        data  = { profiles: {}, participants: [] }
        area  = Atlas::Dataset.find(@graph.area.area_code)

        order.participants.producers.each do |producer|
          if producer.number_of_units > 0 && ! producer.is_a?(Merit::Flex::Base)
            data[:participants].push(participant_data(producer))
          end
        end.compact

        data[:participants].map { |p| p[:profile] }.uniq.compact.each do |key|
          data[:profiles][key] ||= area.load_profile(key).to_a
        end

        data
      end

      private

      def participant_data(participant)
        data = {
          profile: profile_key(participant),
          type:    participant_type(participant)
        }

        attribute_keys(data).each_with_object(data) do |key, data|
          value = participant.public_send(key)
          data[key] = value == Float::INFINITY ? 0.0 : value
        end
      end

      def profile_key(participant)
        @graph.converter(participant.key).converter_api.load_profile_key
      end

      def participant_type(participant)
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
    end # MeritSummaryPresenter
  end # V3
end # Api
