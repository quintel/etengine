module Api
  module V2
    class InputsController < BaseController
      respond_to :xml

      # This action is only used by the energymixer. It returns a minimal list
      # of the available inputs
      def index
        respond_with(@inputs = Input.all.map(&:basic_attributes))
      end
    end
  end
end
