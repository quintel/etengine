# Creates a fake graph, API, and area capable of being used in calculations
# relating to household heat, EVs, and other curves.
module HouseholdCurvesHelper
  # Public: Creates a household heat curve set
  def create_curve_set(dataset: :nl, variant: 'default')
    Qernel::Plugins::TimeResolve::CurveSet.with_dataset(
      Atlas::Dataset.find(dataset), 'heat', variant
    )
  end

  # Public: Creates a basic graph, graph API, and area stub.
  def create_graph(**area_attributes)
    area_attributes = { area_code: :nl }.merge(area_attributes)

    double(
      Qernel::Graph,
      query: double(Qernel::GraphApi),
      area:  double(Qernel::Area, area_attributes)
    )
  end
end
