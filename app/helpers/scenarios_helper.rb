module ScenariosHelper
  RegionGroup = Struct.new(:name, :regions) do
    def human_name
      name.to_s.humanize
    end
  end

  def grouped_region_options
    grouped_region_types.map do |group|
      [group.human_name, group.regions.map { |region| [region.key, region.key] }]
    end
  end

  def grouped_region_types
    order = %i[country region province municipality neighbourhood]
    codes = Etsource::Dataset.region_codes.sort_by { |code| code.to_s.downcase }

    grouped = {}

    codes.each do |code|
      dataset = Atlas::Dataset.find(code)
      group = (grouped[dataset.group] ||= RegionGroup.new(dataset.group, []))
      group.regions.push(dataset)
    end

    grouped.values.sort_by { |g| [order.index(g.name) || Float::INFINITY, g.human_name] }
  end
end
