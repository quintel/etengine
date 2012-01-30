class Etsource::CommitsController < ApplicationController
  layout 'etsource'
  
  authorize_resource :class => false

  # data/latest/etsource/commits/current
  def show
  end

  def index
    @etsource = Etsource::Base.new
    # @etsource.current_branch is sometimes (no branch) catch this
    @branch = params[:branch] || @etsource.current_branch || 'master'
    @etsource.checkout @branch
    @output = @etsource.refresh if params[:commit] == 'Refresh'
    @commits = @etsource.commits
    @branches = @etsource.branches
  end

  def import
    @commit = Etsource::Commit.new(params[:id])
    @commit.import!
    flash.now[:notice] = "It is now a good idea to refresh the gquery cache on all clients (ETM, Mixer, ...)"
  end
end
