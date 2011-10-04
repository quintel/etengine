class Data::CommitsController < Data::BaseController
  skip_before_filter :find_graph

  before_filter :init_git
  
  set_tab :commits

  def index
    @commits = @git.log
  end

  def show
    @etsource = Etsource::Commit.new(params[:id])
    @commit = @etsource.commit
    @etsource.import!
  end
  
  def init_git
    @git = Git.open('etsource')
    @git.checkout(params[:branch], :force => true)
    `cd etsource; git pull`
    @git.pull if params[:refresh]
  end

end
