# frozen_string_literal: true

# Fetches sets of scenario ids to quickly filter for preset queries when dumping scenarios for testing
class ScenarioSetFetcher
  # @param type     [String]   'user_input' or 'featured'
  # @param ids      [Array<Integer>] only for user_input
  # @param end_year [Integer]      only for featured
  # @param group    [String]       only for featured
  #
  # @return [Array<Integer>] the scenario IDs
  def self.fetch(type:, ids: [], end_year: nil, group: nil)
    case type.to_s
    when 'user_input'
      fetch_user_input(ids)
    when 'featured'
      fetch_featured(end_year, group)
    else
      []
    end
  end

  private_class_method def self.fetch_user_input(ids)
    Array(ids).map(&:to_i).reject(&:zero?).uniq
  end

  private_class_method def self.fetch_featured(year, group)
    return [] unless year && group

    groups = MyEtm::FeaturedScenario.in_groups_per_end_year[year] || []
    data   = groups.find { |g| g[:name] == group }
    data ? data[:scenarios].map(&:scenario_id) : []
  end
end
