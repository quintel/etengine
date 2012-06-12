# Represents a mechanical turk _spec.rb file. Helps finding
# and running tests.
#
module MechanicalTurk
  class Turk
    attr_reader :filepath, :etsource_dir

    def initialize(filepath)
      @filepath = Pathname.new(filepath)
      @etsource_dir = Pathname.new @filepath.to_s.match(/(.+)\/mechanical_turk/).captures.first
    end

    def run
      puts "** #{rspec_command}"
      system(rspec_command)
    end

    def rspec_command
      "ETSOURCE_DIR='#{@etsource_dir}' #{rspec_binary} #{@filepath}"
    end

    def rspec_binary
      File.exists?("bin/rspec") ? 'bin/rspec' : 'rspec'
    end

    def self.all
      base_dir = Etsource::Base.instance.base_dir
      Dir.glob(base_dir+"/**/mechanical_turk/**/*_spec.rb").map do |turk_file|
        new(turk_file)
      end
    end
  end
end