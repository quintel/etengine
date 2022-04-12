class BulkUpdateHelpers
  class << self
    def save(scenario, user_values,  dry_run = true)
      return show_diff(scenario, user_values) if dry_run

      if user_values != scenario.user_values
        scenario.update(:user_values => user_values)
        true
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

  desc 'Updates the scenarios.'
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

    defaults_dir   = Rails.root.join("tmp/input_values")
    defaults_files = Pathname.glob(defaults_dir.join('*.yml'))

    @defaults = defaults_files.each_with_object({}) do |path, data|
      data[path.basename('.yml').to_s.to_sym] = YAML.load_file(path)
    end

    update_block = lambda { |s, reporter|
      puts "#{s.class} ##{s.id}: #{s.title}" if @dry_run

      # cleanup unused scenarios
      if s.area_code.blank? ||
            # Deleted region.
            @defaults[s.area_code.to_sym].nil? ||
            # Old scenario.
            (!s.keep_updated? && s.title == "API" && s.updated_at < 365.days.ago ) ||
            # Internal use.
            s.source == "Mechanical Turk" ||
            # Very old scenario.
            s.user_values.keys.any? { |k| k.is_a?(Numeric) }
        if @dry_run
          puts "> Would be removed, but this is a dry run"
        else
          reporter.inc(:removed) if reporter
          s.destroy
        end
        next
      end

      begin
        inputs = s.user_values.symbolize_keys
      rescue
        reporter.inc(:failed) if reporter
        next
      end

      rec = Atlas::ScenarioReconciler.new(inputs, @defaults[s.area_code.to_sym])
      inputs = inputs.merge(rec.to_h).with_indifferent_access

      # Rounding all inputs
      inputs.each do |x|
        x[1] = x[1].to_f.round(1) unless x[1].nil?
      end

      puts "===========" if @dry_run

      ######################## END ############################
      if BulkUpdateHelpers.save(s, inputs, @dry_run)
        reporter.inc(:updated) if reporter
      else
        reporter.inc(:unchanged) if reporter
      end
    }

    if ! ENV['PERFORM']
      puts "Help:"
      puts "-----"
      puts "Append the following options to the rake command:"
      puts "PERFORM=1  Run the actions (as in, don't do a dry run)"
    end


    groups = { unchanged: :green, updated: :yellow,
               removed: :yellow, failed: :red }

    title  = 'Updating scenarios'

    reporter = Atlas::Term::Reporter.new(title, groups)

    Scenario.order('id').find_each(:batch_size => 100) do |scenario|
      begin
        update_block.call(scenario, @dry_run ? nil : reporter)
      rescue Exception => ex
        puts "#{ ex.class } raised processing: ##{ scenario.id }"
        raise ex
      end
    end

    reporter.send(:refresh!, true) unless @dry_run
  end # update_scenarios
end # bulk_update
