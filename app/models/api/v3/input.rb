module Api
  module V3
    class Input
      def initialize(id = nil, scenario = nil)
        raise "Missing identifier" unless id
        raise "Missing scenario" unless scenario
        @scenario = scenario
        # An input should be found by id and by key as needed
        @input = if id.to_i != 0
          ::Input.find(id) rescue nil
        else
          ::Input.find_by_key(id)
        end
        raise "Input not found" unless @input
      end

      def to_json(options = {})
        Jbuilder.encode do |json|
          json.code @input.key
          json.share_group @input.share_group
        end
      end
    end
  end
end
