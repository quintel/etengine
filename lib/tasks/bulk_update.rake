class BulkUpdateHelpers
  class << self
    def save(object, user_values,  dry_run = true)
      if object.is_a?(Preset)
        save_preset(object, user_values, dry_run)
      elsif object.is_a?(Scenario)
        save_scenario(object, user_values, dry_run)
      end
    end

    def show_diff(object, user_values)
      keys = (
        object.user_values.keys.map(&:to_sym) +
        user_values.keys.map(&:to_sym)
      ).compact

      keys.each do |key|
        original = object.user_values[key]
        updated  = user_values[key]

        if original != updated
          f_original = original.nil? ? 'nil' : original.to_f
          f_updated  = updated.nil? ? 'nil' : updated.to_f

          puts "Different value in #{key}: #{f_original} -> #{f_updated}"
        end
      end
    end

    #######
    private
    #######

    def save_preset(preset, user_values, dry_run)
      return show_diff(preset, user_values) if dry_run

      atl_preset = Atlas::Preset.find(preset.key)

      atl_preset.user_values = user_values
      atl_preset.save(false)
    end

    def save_scenario(scenario, user_values, dry_run)
      return show_diff(scenario, user_values) if dry_run

      puts "> Saving!"
      scenario.update_attributes(:user_values => user_values)
    end

    def preset_dir
      @preset_dir ||= File.join(Etsource::Base.instance.base_dir, 'presets')
    end

    # Returns Hash containing key-value pairs with ID and path of individual
    # presets
    def get_file_data
      file_data = {}
      Dir.glob("#{preset_dir}/**/*.yml").each do |f|
        file = YAML::load_file(f).with_indifferent_access
        file_data[file[:id]] = { path: f }
      end
      file_data
    end
  end
end

namespace :bulk_update do
  task preamble: :environment do
    require 'highline/import'
    require 'term/ansicolor'

    include Term::ANSIColor
  end

  desc "This shows the changes that would be applied to gqueries. Pass FORCE=TRUE to update records"
  task :gquery_replace => 'bulk_update:preamble' do
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
  task :input_replace => 'bulk_update:preamble' do
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

  desc 'Updates the scenarios. Add PRESETS=1 to only update preset scenarios'
  task :update_scenarios => ['bulk_update:preamble', 'inputs:dump'] do
    @dry_run = !ENV['PERFORM']

    if @dry_run
      puts "=== Doing a dry run! (run with PERFORM=1 to execute changes.)"
    else
      @dry_run = !HighLine.agree("Are you sure you want to perform the updates? [y/n]")

      if @dry_run
        puts "=== You have forced to perform, but decided on a dry run."
      else
        puts "=== Doing the changes."
      end
    end

    update_block = proc { |s|
      puts "#{s.class} ##{s.id}: #{s.title}"

      #skip scenario if not nl
      next unless s.area_code == "nl"

      # cleanup unused scenarios
      if s.is_a?(Scenario) && (s.area_code.blank? || (s.title == "API" && s.updated_at  < 14.day.ago ) || s.source == "Mechanical Turk")
        if @dry_run
          puts "> Would be removed, but this is a dry run"
        else
          puts "> REMOVING"
          s.destroy
        end
        next
      end

      begin
        inputs = s.user_values.symbolize_keys
      rescue
        puts "> Error! cannot load user_values"
        next
      end

      rec = Atlas::ScenarioReconciler.new(
        inputs,
        YAML.load_file(Rails.root.join("tmp/input_values/#{ s.area_code }.yml"))
      )

      inputs = inputs.merge(rec.to_h).with_indifferent_access

      # Rounding all inputs
      inputs.each do |x|
        x[1] = x[1].to_f.round(1) unless x[1].nil?
      end

      puts "==========="

      ######################## END ############################
      BulkUpdateHelpers.save(s, inputs, @dry_run)
    }

    if !ENV['PRESETS'] && !ENV['SCENARIOS']
      puts "Help:"
      puts "-----"
      puts "Append the following options to the rake command:"
      puts "PRESETS=1       Run on the presets"
      puts "SCENARIOS=1     Run on the scenarios"
      puts "PERFORM=1       Run the actions (as in, don't do a dry run)"
    end

    # Update presets
    if !!ENV['PRESETS']
      Preset.all.each do |preset|
        update_block.call preset
      end
    end

    if !!ENV['SCENARIOS']
      Scenario.order('id').find_each(:batch_size => 100) do |scenario|
        update_block.call scenario
      end
    end
  end
end
