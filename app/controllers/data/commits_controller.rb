class Data::CommitsController < Data::BaseController
  skip_before_filter :find_graph
  # before_filter :init_git, :only => :index

  set_tab :commits

  def index
    @etsource = Etsource::Base.new
    @branch = params[:branch] || 'master'
    @etsource.checkout @branch
    @commits = @etsource.commits
    @branches = @etsource.branches
  end

  def import
    @etsource = Etsource::Commit.new(params[:id])
    @commit = @etsource.commit
    @etsource.import!
    flash.now[:notice] = "It is now a good idea to refresh the gquery cache on all clients (ETM, Mixer, ...)"
  end

  private

    def init_git

      @git = Git.open('etsource')
      @output = @git.fetch
      @git.checkout(@branch)
      @git.pull
    end
end
