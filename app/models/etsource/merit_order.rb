module Etsource
  class MeritOrder
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def import
      Rails.cache.fetch('merit_order_hash') do
        file = "#{@etsource.export_dir}/datasets/_globals/merit_order.yml"
        YAML.load_file file
      end
    rescue Exception => e
      raise "Error loading merit order data: #{e.message}"
    end
  end
end