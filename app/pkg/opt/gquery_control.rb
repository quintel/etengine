module Opt
  # This class controls the gquery stuff
  class GqueryControl
    attr_accessor :target,
                  :weight

    attr_reader :gquery, :id

    #
    #
    def initialize(gquery, target, weight, options = {})
      @id = gquery.id
      @gquery = gquery
      @target = target.to_f
      @weight = weight.to_f
      @options = options
    end

    ##
    # @return [Float] The GQL calculated future value of this query
    #
    def future_value
      Current.gql.query(@gquery.query).future_value
    end

    ##
    # the distance to the target value. 
    # depends if the lower_is_better or higher_is_better.
    #
    # closer to 1 is better. 
    # 0 is target_met?
    #
    # @return [Float]
    #
    def fitness
      if target_met?
        0
      elsif target == 0.0
        0.0
      else
        t = future_value / target # 10.0 / 8.0 
        t = 0.0 if t.nan? or t.infinite?
        t
      end 
    end

    ##
    # @return [Float] The fitness * weight
    #
    def weighted_fitness
      fitness * weight
    end

    ##
    # @return [true, false] Is the current future value less then the target?
    #
    def target_met?
      future_value < target
    end

    def to_json(options = {})
      ActiveSupport::JSON.encode({:gquery_control => {
          :id => self.gquery.id, 
          :fitness => self.fitness}
      }) 
    end
  end
end