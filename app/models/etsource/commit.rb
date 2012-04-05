module Etsource
  class Commit
    attr_accessor :commit

    def initialize(commit)
      @etsource = Etsource::Base.instance
    end

    def import!
      
    end

    def message
      commit.message
    end
  end
end
