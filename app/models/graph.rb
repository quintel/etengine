# == Schema Information
#
# Table name: graphs
#
#  id           :integer(4)      not null, primary key
#  blueprint_id :integer(4)
#  dataset_id   :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

##
#
# Graph replaces ::Graph in the blueprint way of doing things. A Graph is the thing that a user
# will choose and use. It references a blueprint, which defines the structure of the graph, and a graph,
# which defines the data.
#
# The graph_id formerly used to reference ::Graph now references both a Graph *and* a Dataset. That
# is, the graph.id == graph.dataset.id
#
# The user would select a Graph, which can be looked up by id, i.e.
# Graph.find(graph_id)
#
#
class Graph < ActiveRecord::Base
  belongs_to :blueprint # blueprint for the graph
  belongs_to :dataset, :dependent => :destroy # data for the graph

  scope :ordered, order('created_at DESC')

  delegate :description, :to => :blueprint

  def country
    dataset.region_code
  end

  def version
    blueprint.graph_version
  end

  @@future_qernels = {}
  @@present_qernels = {}

  # to be returned by Current.graph, Graph needs to provide the methods
  # latest_from_country, gql, create_gql
  def self.latest_from_country(country)
    self.find_by_dataset_id(Dataset.latest_from_country(country).id)
    #Graph.ordered.country(country).first
  end

  def gql
    @gql ||= ::Gql::Gql.new(self)
  end

  def present
    @present_graph ||= calculated_present_qernel
  end

  def future
    @future_graph = nil

    Graph.benchmark("Graph#future qernel") do
      @future_graph = self.class.future_qernel_for(self)
    end

    # Graph.benchmark("Graph#future dataset") do
    #   @future_graph.dataset = dataset.to_qernel
    # end

    @future_graph
  end

  def present_qernel
    self.class.present_qernel_for(self)
  end

  ##
  #
  #
  def calculated_present_qernel
    qernel = nil
    Graph.benchmark("Graph#calculated_present_qernel qernel") do
      qernel = present_qernel
    end
    # Graph.benchmark("Graph#calculated_present_qernel dataset") do
    #   qernel.dataset = calculated_present_data
    # end
    qernel
  end

  def calculated_present_data
    marshal = Rails.cache.fetch("/graph/#{dataset.id}/#{dataset.updated_at.to_i}/calculated_present_data") do
      qernel = present_qernel
      qernel.dataset = dataset.to_qernel
      qernel.calculate
      Marshal.dump(qernel.dataset)
    end
    Marshal.load marshal
  end

  def self.present_qernel_for(graph)
    # TODO seb: should probably be graph.blueprint_id
    @@present_qernels[graph.id] ||= graph.to_qernel
  end

  def self.future_qernel_for(graph)
    # TODO seb: should probably be graph.blueprint_id
    @@future_qernels[graph.id] ||= graph.to_qernel
  end

  ##
  # Build a Qernel::Graph
  #
  # @return [Qernel::Graph]
  def to_qernel
    return false unless dataset
    marshal = Rails.cache.fetch("/graph/#{id}/#{dataset.updated_at.to_i}") do
      Marshal.dump(build_qernel)
    end
    Marshal.load marshal
  end

  def build_qernel
    qernel = blueprint.to_qernel
    qernel.dataset = dataset.to_qernel
    qernel.optimize_calculation_order
    qernel.reset_dataset_objects
    qernel.dataset = nil
    qernel
  end
end
