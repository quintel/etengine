class Data::GqlTestCasesController < Data::BaseController
  layout 'gql_test_cases'

  skip_before_filter :find_graph
  before_filter :find_model, :only => [:show, :edit, :update, :destroy]

  def index
    @gql_test_cases = GqlTestCase.all
    render :layout => 'data'
  end

  def show
  end

  def edit
  end

  def new
    #
    @gql_test_case = GqlTestCase.new(:instruction => "var settings = 'settings[scenario_id]=#{params[:scenario_id]}';")
    respond_to do |format|
      format.html {}
      format.text {}
    end
  end

  def create
    @gql_test_case = GqlTestCase.new(params[:gql_test_case])
    if @gql_test_case.save
      redirect_to data_gql_test_cases_url
    end
  end

  def destroy
    @gql_test_case.destroy
    flash[:notice] = 'Test Case deleted'
    redirect_to data_gql_test_cases_url
  end

  def update
    if @gql_test_case.update_attributes(params[:gql_test_case])
      redirect_to data_gql_test_cases_url
    end
  end

  private
  
    def find_model
      @gql_test_case = GqlTestCase.find(params[:id])
    end
end
