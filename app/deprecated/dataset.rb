# == Schema Information
#
# Table name: datasets
#
#  id           :integer(4)      not null, primary key
#  blueprint_id :integer(4)
#  region_code  :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  area_id      :integer(4)
#

class Dataset < ActiveRecord::Base
  has_one :graph
  belongs_to :blueprint
  belongs_to :area

  has_many :converter_datas, :dependent => :delete_all
  has_many :link_datas, :dependent => :delete_all
  has_many :slot_datas, :dependent => :delete_all

  # TODO: something wrong here with graph_id. graph_id refers to :graph in TimeCurveEntry
  has_many :time_curve_entries, :foreign_key => 'graph_id', :dependent => :delete_all

  # named scopes for finding graphs by version/country/creation date
  scope :version, lambda {|version| where(:graph_version => version) } # CHECK missing column!
  scope :region_code, lambda {|region_code| where(:region_code => region_code) }
  scope :ordered, order("created_at DESC")

  def carrier_area_datas
    CarrierData.where(:area_id => area)
  end

  def self.latest_from_country(region_code)
    ordered.region_code(region_code).first
  end

  ##
  # Dataset qernel instances are cached based on last update date.
  #
  # @return [Qernel::Dataset] a memcached clone of the qernel object
  #
  def to_qernel
    marshal = Rails.cache.fetch("/dataset/#{id}/#{updated_at.to_i}") do
      Marshal.dump(build_qernel)
    end
    Marshal.load marshal
  end

  # @return [Qernel::Dataset] The calculated present dataset.
  def to_calculated_qernel
    marshal = Rails.cache.fetch("/datasets/#{self.id}/#{self.updated_at.to_i}/calculated_qernel") do
      graph = self.graph.present_qernel
      graph.dataset = to_qernel
      graph.calculate
      Marshal.dump(graph.dataset)
    end
    Marshal.load marshal
  end

  def time_curves
    entries = self.time_curve_entries
    time_curves = entries.select(&:preset_demand?).group_by(&:converter_id)
    time_curves.each do |key,arr|
      hsh = {}
      arr.each do |serie|
        hsh[serie.value_type] ||= {}
        hsh[serie.value_type][serie.year] = serie.value
      end
      time_curves[key] = hsh
    end
    time_curves
  end


  def to_label
    "#{blueprint_id} - #{created_at}"
  end

  private

    def build_qernel
      qernel = Qernel::Dataset.new(id)

      # [converter_datas, carrier_area_datas, area, link_datas, slot_datas].each do |data|
      #   qernel.add_data data
      # end
      qernel.add_dataset(converter_datas, carrier_area_datas, link_datas, slot_datas, area)
      qernel.time_curves = time_curves
      qernel
    end

    def copy_converter_datas_to!(dataset)
      converter_datas.each do |converter_data|
        dataset.converter_datas << converter_data.clone
      end
    end

    def copy_link_datas_to!(dataset)
      new_links = dataset.blueprint.links
      link_datas.each do |link_data|
        link = link_data.link
        new_link = new_links.detect{|l|
          l.parent_id == link.parent_id &&
          l.child_id == link.child_id &&
          l.carrier_id == link.carrier_id &&
          l.link_type == link.link_type
        }
        new_link_data = link_data.clone
        new_link_data.link_id = new_link.id

        dataset.link_datas << new_link_data
      end
    end

    def copy_slot_datas_to!(dataset)
      new_slots = dataset.blueprint.slots
      slot_datas.each do |slot_data|
        slot = slot_data.slot
        new_slot = new_slots.detect{|l|
          l.converter_id == slot.converter_id &&
          l.carrier_id == slot.carrier_id &&
          l.direction == slot.direction
        }
        new_slot_data = slot_data.clone
        new_slot_data.slot_id = new_slot.id

        dataset.slot_datas << new_slot_data
      end
    end

    def copy_time_curve_entries_to!(dataset)
      time_curve_entries.each do |time_curve_entry|
        dataset.time_curve_entries << time_curve_entry.clone
      end
    end
end
