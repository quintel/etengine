require 'highline/import'
require 'term/ansicolor'
include Term::ANSIColor

namespace :bulk_update do
  desc "This shows the changes that would be applied to gqueries. Pass FORCE=TRUE to update records"
  task :gquery_replace => :environment do
    bootstrap

    @gqueries = Gquery.contains(@from)
    @gqueries.each do |g|
      puts "GQuery #{g.id}".yellow.bold
      puts "Query was: #{highlight(g.query, @from)}"
      g.query = g.query.gsub(@from, @to)
      puts "Query will be: #{highlight(g.query, @to)}"
      puts
      if @force
        puts "Saving record!".green
        g.save
      end
    end
  end

  desc "This shows the changes that would be applied to inputs. Pass FORCE=TRUE to update records"
  task :input_replace => :environment do
    bootstrap
    @inputs = Input.embedded_gql_contains(@from)
    @inputs.each do |i|
      puts "Input #{i.id}".yellow.bold
      [:start_value_gql, :min_value_gql, :max_value_gql, :attr_name].each do |field|
        value = i.send(field)
        next if value.blank?
        next unless value.include?(@from)
        puts "#{field} was: #{highlight(value, @from)}"
        i.send("#{field}=", value.gsub(@from, @to))
        puts "#{field} will be: #{highlight(i.send(field), @to)}"
      end
      puts
      if @force
        puts "Saving record!".green
        i.save
      end
    end
  end

  def bootstrap
    @from  = ENV["FROM"]
    @to    = ENV["TO"]
    @force = ENV["FORCE"] == "TRUE"

    if @force
      unless HighLine.agree("You know what you're doing, right? [y/n]")
        puts "Bye"; exit
      end
    end

    if @from.blank? || @to.blank?
      puts "Missing FROM/TO attribute"; exit
    end
  end

  def highlight(text, token)
    text.gsub(token, token.red)
  end

  task :update_scenarios => :environment do
    @update_records = HighLine.agree("You want to update records, right? [y/n]")
    #counter = 0
    Scenario.order('id').find_each(:batch_size => 100) do |s|
      puts "Scenario ##{s.id}"

      if s.area_code.blank?
        puts "skipping Scenario"
        next
      end

      begin
        inputs = s.user_values
      rescue
        puts "Error!"
        next
      end
      # ...
      # ...
      # to add or change a new input value:
      # inputs[123] = 567.789789
      #
      # to remove a slider values
      # inputs.delete(123)
      #
      # to get a value
      # inputs[123]
      #
      # Important: slider ids must be integers!
      # inputs["123"] != inputs[123]
      #
      # To see what's going on
      # inputs.to_yaml
      
      ##########################################################
      # Following lines describe the changes of scenarios in the
      # deploy of July 10 2012

      share_group_inputs = [333, 338, 51, 582, 340, 375, 317, 52, 441, 248, 411, 421, 420,
        444, 445, 446, 347, 439, 346, 435, 443, 585,
        386, 388, 385, 593, 381, 382, 588]
      
      share_group_inputs.each do |element|
        inputs[element] = 0.0 if inputs[element].nil?
        #puts "inputs[" + element.to_s + "] = " + inputs[element].to_s
      end

      # HHs heatpump add-on
      inputs[339] = (inputs[339] / 0.6).round(1) unless inputs[339].nil?
      
      # HHs solar thermal panel
      demand_space_heating = 298.91
      demand_hot_water = 96.17
      inputs[48] = 0.0 if inputs[48].nil?
      inputs[348] = (( inputs[348] * demand_hot_water + inputs[48] * demand_space_heating ) / ( 0.5 * demand_hot_water + 0.15 * demand_space_heating )).round(1)  unless inputs[348].nil?

      # Sliders in HHs space heating should add up to 100%
      sum = 
      inputs[333]+
      inputs[338]+
      inputs[51 ]+
      inputs[582]+
      inputs[340]+
      inputs[375]+
      inputs[317]+
      inputs[52 ]+
      inputs[441]+
      inputs[248]+
      inputs[411]
      
      if sum>0.0
      
        factor = sum/100.0
        inputs[333] = (inputs[333]/factor).round(1)
        inputs[338] = (inputs[338]/factor).round(1)
        inputs[51 ] = (inputs[51 ]/factor).round(1)
        inputs[582] = (inputs[582]/factor).round(1)
        inputs[340] = (inputs[340]/factor).round(1)
        inputs[375] = (inputs[375]/factor).round(1)
        inputs[317] = (inputs[317]/factor).round(1)
        inputs[52 ] = (inputs[52 ]/factor).round(1)
        inputs[441] = (inputs[441]/factor).round(1)
        inputs[248] = (inputs[248]/factor).round(1)
        inputs[411] = (inputs[411]/factor).round(1)
      
      end
      
      # Sliders in HHs hot water should add up to 100%
      sum = 
      inputs[446]+
      inputs[421]+
      inputs[420]+
      inputs[444]+
      inputs[445]+
      inputs[347]+
      inputs[439]+
      inputs[346]+
      inputs[435]+
      inputs[443]
      
      if sum>0.0 
        
        factor = sum/100.0
        inputs[446]=(inputs[446]/factor).round(1)
        inputs[421]=(inputs[421]/factor).round(1)
        inputs[420]=(inputs[420]/factor).round(1)
        inputs[444]=(inputs[444]/factor).round(1)
        inputs[445]=(inputs[445]/factor).round(1)
        inputs[347]=(inputs[347]/factor).round(1)
        inputs[439]=(inputs[439]/factor).round(1)
        inputs[346]=(inputs[346]/factor).round(1)
        inputs[435]=(inputs[435]/factor).round(1)
        inputs[443]=(inputs[443]/factor).round(1)
      end
      
      # Sliders in Buildings district heating should add up to 100%
      sum =
      inputs[386]+
      inputs[388]+
      inputs[385]+
      inputs[593]
      
      # This is the new district heating input
      inputs[585] = sum.round(1)
      
      if sum>0.0
        factor = sum/100.0        
        inputs[386]=(inputs[386]/factor).round(1)
        inputs[388]=(inputs[388]/factor).round(1)
        inputs[385]=(inputs[385]/factor).round(1)
        inputs[593]=(inputs[593]/factor).round(1)     
      end
      
      # Buildings insulation
      inputs[381]=([inputs[381], inputs[382]].min).round(1)
      
      # Transport fuels should have gasoline - > 0 (new slider)
      inputs[588]=0.0
      
      # Heavy fuel oil should be zero (new slider)
      inputs[589]=0.0
      
      # Delete old inputs
      inputs.delete(48)
      inputs.delete(382)
      
      #puts inputs
      
      #inputs.each do |element|
        #puts element[0].to_s + "," + element[1].to_s
      #end
      
      ################ END ####################################
      
      if @update_records
        puts "saving"
        s.update_attributes!(:user_values => inputs) #if counter !=0
      end
      
      #counter += 1
      #exit if counter ==  1
    end
  end
end
