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

  def scenario_mutability_select(form)
    form.input(
      :mutability,
      include_blank: false,
      collection: [
        ['Read and write', 'public'],
        ['Read and write; keep compatible with model updates', 'keep-compatible'],
        ['API read-only; keep compatible with model updates', 'api-read-only']
      ],
      input_html: { style: 'width: auto' }
    )
  end

  def formatted_scenario_mutability(scenario)
    if scenario.api_read_only?
      tag.a('Read-only (API)', class: 'tag orange', href: 'https://docs.energytransitionmodel.com/api/scenario-basics#read-only-scenarios')
    else
      tag.a('Read and write', class: 'tag gray', href: 'https://docs.energytransitionmodel.com/api/scenario-basics#read-only-scenarios')
    end
  end

  def formatted_scenario_compatibility(scenario)
    if scenario.keep_compatible?
      tag.a('Keep compatible', class: 'tag green', href: 'https://docs.energytransitionmodel.com/api/scenario-basics#forward-compatibility')
    elsif scenario.outdated?
      tag.span('Outdated - not guaranteed', class: 'tag red')
    else
      tag.span('Current model version only', class: 'tag gray')
    end
  end
end
