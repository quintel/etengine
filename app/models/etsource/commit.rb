module Etsource
  class Commit
    attr_reader :commit

    def initialize(commit)
      @etsource = Base.new
      @etsource.checkout_commit(commit)
    end

    def import!
      Gquery.transaction do
        GqlTestCases.new(@etsource).import!
        Gqueries.new(@etsource).import!
        Inputs.new(@etsource).import!
      end
      # DEBT fix this properly
      `curl http://beta.et-model.com/pages/refresh_gqueries > /dev/null`
    end
  end
end