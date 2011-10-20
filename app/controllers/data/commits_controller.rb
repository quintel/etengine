class Data::CommitsController < Data::BaseController
  skip_before_filter :find_graph
  before_filter :init_git

  set_tab :commits

  def index
    @commits = @git.log
  end

  def import
    @etsource = Etsource::Commit.new(params[:id])
    @commit = @etsource.commit
    @etsource.import!
  end

  private

    def init_git
      @branch = params[:branch] || 'master'
      @git = Git.open('etsource')
      @git.checkout(@branch, :force => true)
      # DEBT solve properly
      `cd etsource; git pull`
      @git.pull if params[:refresh]
    end
end
