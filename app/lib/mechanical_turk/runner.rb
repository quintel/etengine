# Represents a mechanical turk _spec.rb file. Helps finding
# and running tests.
#
module MechanicalTurk
  class Runner
    attr_reader :turk

    # @param [MechanicalTurk::Turk] turk
    def initialize(turk)
      @turk = turk
    end

    def run(type = :system)
      puts "** #{rspec_command}"
      case type
      when :system then system(rspec_command)
      when :ticks  then `#{rspec_command}`
      when :x      then %x[#{rspec_command}]
      end
    end

    def rspec_command
      "RAILS_ENV=test ETSOURCE_DIR='#{turk.etsource_dir}' #{rspec_binary} #{turk.filepath}"
    end

    def rspec_binary
      File.exists?("bin/rspec") ? 'bin/rspec' : 'rspec'
    end

  end
end
