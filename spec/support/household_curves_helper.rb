# Creates a fake graph, API, and area capable of being used in calculations
# relating to household heat, EVs, and other curves.
module HouseholdCurvesHelper

  # Public: Creates a fake graph for household heat calculations.
  #
  # graph     - A stubbed graph.
  # old_share - The share of old households to new households. If this is 0.6
  #             (60%) then it is assumed new households account for 40% of
  #             households. (default: 0.75)
  # old_level - The level of insulation installed in old households. 0.0 means
  #             to use exclusively the "non_insulated" profile, 1.0 to use the
  #             "insulated" profile. (default: 0.25)
  # new_level - See :old_insulation_level. (default: 0.75)
  # demand    - The total amount of demand for heat-related electricity.
  #             (default: 10.0)
  #
  # Returns the graph.
  def stub_space_heating(
      graph,
      demand: 10.0,
      old_share: 0.75,
      old_level: 0.25,
      new_level: 0.75
  )
    area = graph.area

    allow(graph.query)
      .to receive(:group_demand_for_electricity)
      .with(:merit_household_space_heating_producers)
      .and_return(demand)

    # Set up levels of insulation in households.

    allow(area).to receive(:insulation_level_old_houses_min).and_return(0.0)
    allow(area).to receive(:insulation_level_new_houses_max).and_return(1.0)

    allow(area).to receive(:insulation_level_old_houses).and_return(old_level)
    allow(area).to receive(:insulation_level_new_houses).and_return(new_level)

    # Set up household heat converters which determine the share of old to new
    # households.

    allow(graph).to receive(:group_converters).with(:merit_old_household_heat)
      .and_return([double(Qernel::ConverterApi, demand: old_share)])

    allow(graph).to receive(:group_converters).with(:merit_new_household_heat)
      .and_return([double(Qernel::ConverterApi, demand: 1 - old_share)])

    graph
  end

  # Public: Creates a fake graph for household hot water calculations.
  #
  # graph  - A stubbed graph.
  # demand - The demand for hot water. (default: 10.0)
  #
  # Returns the graph.
  def stub_hot_water(graph, demand: 10.0)
    allow(graph.query)
      .to receive(:group_demand_for_electricity)
      .with(:merit_household_hot_water_producers)
      .and_return(demand)

    graph
  end

  # Public: Creates a household heat curve set
  def create_curve_set(dataset: :nl, variant: 'default')
    Qernel::Plugins::TimeResolve::CurveSet.with_dataset(
      Atlas::Dataset.find(dataset), 'heat', variant
    )
  end

  # Public: Creates a basic graph, graph API, and area stub.
  def create_graph(area_code: :nl)
    double(
      Qernel::Graph,
      query: double(Qernel::GraphApi),
      area:  double(Qernel::Area, area_code: area_code)
    )
  end
end
