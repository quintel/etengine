# frozen_string_literal: true

module ScenarioPacker
  class DumpCollection
    # Accepts an Array of IDs
    #
    # @param [Array<Integer>] ids
    def initialize(ids)
      @ids = Array(ids).map(&:to_i).uniq
      @records_by_id = Scenario.where(id: @ids)
                               .index_by(&:id)
    end

    # Returns an Array of Hashes, one per scenario
    #
    # @return [Array<Hash{Symbol=>Object}>]
    def as_json(*)
      @ids.filter_map do |id|
        record = @records_by_id[id]
        next unless record

        Dump.new(record).as_json
      end
    end

    # Pretty-printed JSON string
    #
    # @return [String]
    def to_json(*)
      JSON.pretty_generate(as_json(*))
    end

    # Derive a filename from the scenario IDs
    #
    # @return [String]
    def filename
      "#{@ids.join('-')}-dump.json"
    end
  end
end
