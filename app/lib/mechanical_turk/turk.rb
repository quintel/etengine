# Represents a mechanical turk _spec.rb file. Helps finding
# and running tests.
#
module MechanicalTurk
  class Turk
    extend ActiveModel::Naming

    attr_reader :filepath, :etsource_dir

    def initialize(filepath)
      @filepath = Pathname.new(filepath)
      @etsource_dir = Pathname.new @filepath.to_s.match(/(.+)\/mechanical_turk/).captures.first
    end

    def id
      Hashpipe.hash(filepath)
    end

    def text
      File.read(filepath)
    end

    def to_param
      id.to_s
    end

    def run(type = :system)
      Runner.new(self).run(type)
    end

    def short_path
      filepath.relative_path_from(@etsource_dir)
    end


    def self.get(id)
      all.detect{ |t| t.to_param == id}
    end

    def self.all
      base_dir = Etsource::Base.instance.base_dir
      Dir.glob(base_dir+"/**/mechanical_turk/**/*_spec.rb").map do |turk_file|
        new(turk_file)
      end
    end
  end
end
