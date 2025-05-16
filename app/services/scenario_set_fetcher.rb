

class ScenarioSetFetcher
  def self.fetch(type:, params:)
    case type.to_s
    when 'featured'
      fetch_featured(params)
    when 'user_input'
      fetch_user_input(params)
    # TODO: add fetching scenarios belonging to a certain user (by email), quintel scenarios, key client scenarios and last 100 scenarios
    else
      []
    end
  end

  def self.fetch_featured(params)
    year  = params[:end_year].to_i
    group = params[:group]
    groups = MyEtm::FeaturedScenario.in_groups_per_end_year[year] || []
    data   = groups.find { |g| g[:name] == group }
    data ? data[:scenarios].map(&:scenario_id) : []
  end

  def self.fetch_user_input(params)
    raw = params[:scenario_ids]
    ids = if raw.is_a?(String)
      raw.split(/\s*,\s*/)
    else
      Array(raw)
    end

    ids.map(&:to_i).reject(&:zero?).uniq
  end
end
