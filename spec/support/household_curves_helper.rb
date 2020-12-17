# Creates a fake graph, API, and area capable of being used in calculations
# relating to household heat, EVs, and other curves.
module HouseholdCurvesHelper
  # Public: Creates a household heat curve set
  def create_curve_set(dataset: :nl, variant: 'default')
    Atlas::Dataset.find(dataset).curve_sets.get('weather').variant(variant)
  end

  # Public: Creates a basic graph, graph API, and area stub.
  def create_graph(**area_attributes)
    area_attributes = { area_code: :nl }.merge(area_attributes)

    graph = instance_double(
      Qernel::Graph,
      query: instance_double(Qernel::GraphApi::Energy),
      area: instance_double(Qernel::Area, area_attributes)
    )

    allow(graph).to receive(:dataset_get)
      .with(:custom_curves)
      .and_return(Gql::CustomCurveCollection.new({}))

    graph
  end
end
