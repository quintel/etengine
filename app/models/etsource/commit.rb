module Etsource
  class Commit
    attr_accessor :commit

    def initialize(commit)
      @etsource = Etsource::Base.instance
    end

    def import!
      Gquery.transaction do
        Gqueries.new(@etsource).import!
        Inputs.new(@etsource).import!
      end
    end

    def message
      commit.message
    end
  end
end
