module Api
  module V2
    class GqueriesController < BaseController
      respond_to :xml

      def index
        respond_with(@gqueries = Gquery.select("`id`, `key`, `deprecated_key`").all)
      end
    end
  end
end
