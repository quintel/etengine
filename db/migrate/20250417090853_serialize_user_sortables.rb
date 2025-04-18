class SerializeUserSortables < ActiveRecord::Migration[7.1]
  require 'msgpack'
  require 'yaml'

  TARGET_MODELS = {
    forecast_storage_orders: 'ForecastStorageOrder',
    hydrogen_supply_orders: 'HydrogenSupplyOrder',
    hydrogen_demand_orders: 'HydrogenDemandOrder',
    households_space_heating_producer_orders: 'HouseholdsSpaceHeatingProducerOrder'
  }.freeze

  def up
    TARGET_MODELS.each do |table_name, model_name|
      say "Serializing #{model_name}#order → MessagePack binary"

      rename_column table_name, :order, :order_old
      add_column    table_name, :order, :binary, limit: 64.kilobytes

      record_class = Class.new(ActiveRecord::Base) do
        self.table_name = table_name.to_s
      end
      record_class.reset_column_information

      record_class.find_each do |record|
        json = record.read_attribute_before_type_cast('order_old')
        next if json.blank? || !json.is_a?(String)

        array = YAML.safe_load(
          json,
          permitted_classes: [Array, String, Symbol],
          aliases: true
        )
        next unless array.is_a?(Array)

        msgpack_blob = array.to_msgpack
        record_class.where(id: record.id).update_all(order: msgpack_blob)
      end
    end
  end
end
