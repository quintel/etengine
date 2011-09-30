class Data::CommitsController < Data::BaseController
  skip_before_filter :find_graph

  before_filter :init_git
  
  set_tab :commits

  def index
    @commits = @git.log
  end

  def show
    @commit = @git.gcommit(params[:id])
    @git.checkout(@commit)
    Etsource::Gqueries.new.import!
  end
  
  def init_git
    @git = Git.open('etsource')
    @git.checkout(params[:branch], :force => true)
    @git.pull if params[:refresh]
  end

end
