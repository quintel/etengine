class Blackbox < ActiveRecord::Base
  belongs_to :graph
  has_many :blackbox_output_serie, :dependent => :destroy
  has_many :blackbox_gqueries, :dependent => :destroy

  before_create :assign_graph
  after_create :calculate_blackbox

  scope :ordered, :order => "created_at DESC"

  def assign_graph
    self[:graph_id] = Graph.latest_from_country(Current.scenario.country).id
  end

  def calculate_blackbox
    BlackboxScenario.all.each do |scenario|
      scenario.load_scenario

      OutputElementSerie.all.each do |serie|
        blackbox_output_serie.create(
          :output_element_serie_id => serie.id,
          :blackbox_scenario_id => scenario.id
        ) rescue nil
      end

      Gquery.all.each do |gquery|
        blackbox_gqueries.create(
          :gquery_id => gquery.id,
          :blackbox_scenario_id => scenario.id
        ) rescue nil
      end

    end
  end
end

# == Schema Information
#
# Table name: blackboxes
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  description :text
#  graph_id    :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#

