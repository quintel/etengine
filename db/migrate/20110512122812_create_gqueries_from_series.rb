# These objects have been removed
class OutputElement < ActiveRecord::Base; end
class OutputElementSerie < ActiveRecord::Base
  belongs_to :output_element
end

class CreateGqueriesFromSeries < ActiveRecord::Migration
  def self.up
    OutputElementSerie.find_each do |serie|
      next if serie.output_element.blank?
      clean_label = serie.label.downcase.gsub(/[^a-z0-9_]/, '_')
      gquery_key = "#{clean_label}_#{serie.output_element.key}"
      # serie.update_attribute :gquery, gquery_name
      Gquery.create(
        :key => gquery_key,
        :query => serie.key
      )
      
    end
  end

  def self.down
  end
end
