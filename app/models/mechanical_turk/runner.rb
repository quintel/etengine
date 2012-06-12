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

    def run
      puts "** #{rspec_command}"
      system(rspec_command)
    end

    def rspec_command
      "ETSOURCE_DIR='#{turk.etsource_dir}' #{rspec_binary} #{turk.filepath}"
    end

    def rspec_binary
      File.exists?("bin/rspec") ? 'bin/rspec' : 'rspec'
    end
    
  end
end