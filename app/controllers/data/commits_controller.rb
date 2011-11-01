class Data::CommitsController < Data::BaseController
  skip_before_filter :find_graph

  set_tab :commits

  def index
    @etsource = Etsource::Base.new
    @branch = params[:branch] || 'master'
    @etsource.checkout @branch
    @output = @etsource.refresh if params[:commit] == 'Refresh'
    @commits = @etsource.commits
    @branches = @etsource.branches
  end

  def import
    @etsource = Etsource::Commit.new(params[:id])
    @commit = @etsource.commit
    @etsource.import!
    flash.now[:notice] = "It is now a good idea to refresh the gquery cache on all clients (ETM, Mixer, ...)"
  end
end
