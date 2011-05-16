namespace :maintenance do
  desc "generate new gqueries from legacy output element series table"
  task :generate_output_elements_queries => :environment do
    # These objects have been removed
    class OutputElement < ActiveRecord::Base; end
    class OutputElementSerie < ActiveRecord::Base
      belongs_to :output_element
    end

    OutputElementSerie.find_each do |s|
      chart_id = s.output_element_id
      if chart_id.blank? || !OutputElement.exists?(chart_id)
        puts "Removing broken output element reference"
        s.destroy
        next
      end
      
      # Now let's create a unique, possibly meaningful name
      label       = s.label.downcase.gsub(/[^a-z0-9_]/, '_')      
      gquery_name = "chart_#{s.label}_#{s.group}_#{s.output_element.key}_#{s.id}"      
      final_name  = gquery_name.downcase.gsub(/[^a-z0-9_]/, '_').gsub(/_{1,}/, '_')
      puts final_name
      
      Gquery.create(
        :key   => final_name,
        :query => s.key
      )
    end    
  end
end