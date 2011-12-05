class Api::GqueriesController < Api::BaseController
  respond_to :xml

  def index
    respond_with(@gqueries = Gquery.select("`id`, `key`, `deprecated_key`").all)
  end
end