# frozen_string_literal: true

module Api
  # The Sessions MyETM has granted based on the token's scenario_access claim
  class ScenarioAccess
    CLAIM = 'scenario_access'

    attr_reader :readable, :writable

    def initialize(claim = nil)
      claim = {} unless claim.is_a?(Hash)

      @writable = ids_in(claim['write'])
      @readable = @writable | ids_in(claim['read'])
    end

    private

    def ids_in(list)
      list.is_a?(Array) ? list.grep(Integer) : []
    end
  end
end
