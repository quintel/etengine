class Api::GqueriesController < ApplicationController
  respond_to :xml

  def index
    respond_with(@gqueries = Gquery.select("`id`, `key`").all)
  end

end