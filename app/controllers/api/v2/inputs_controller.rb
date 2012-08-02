module Api
  module V2
    class InputsController < BaseController
      respond_to :xml

      def index
        respond_with(@inputs = Input.all)
      end
    end
  end
end
