module InputTool
  class WizardsController < BaseController
    before_filter :assign_area_code
    before_filter :assign_scenario

    def index
      @saved_wizards = SavedWizard.area_code(@area_code)
      @stored_wizard_codes = @saved_wizards.map(&:code)
      @new_wizard_codes = Etsource::Wizard.codes - @stored_wizard_codes
    end

    def show
    end

    def compiled
      @form   = SavedWizard.find(params[:id])
      @wizard = Etsource::Wizard.new(@form.code)
    end

    def destroy
      @form = SavedWizard.find(params[:id])
      @form.destroy
      redirect_to input_tool_wizards_url
    end

    def new
      @form   = InputTool::SavedWizard.new(:code => params[:code], :area_code => @area_code)
      @wizard = Etsource::Wizard.new(@form.code)
    end

    def create
      @code = params[:input_tool_saved_wizard][:code]
      @form = InputTool::SavedWizard.new(:code => @code, :area_code => @area_code)
      @form.values = (params[@code] || {}).with_indifferent_access
      if @form.save
        redirect_to edit_input_tool_wizard_path(:id => @form.to_param)
      else
        render :action => 'new'
      end
    end

    def update
      @form = SavedWizard.find(params[:id])
      if @form.update_attributes(:values => params[@form.code].with_indifferent_access)
        flash[:notice] = 'success'
        redirect_to edit_input_tool_wizard_path(id: @form)
      else

        render :action => 'edit'
      end
    end

    def edit
      @form   = SavedWizard.find(params[:id])
      @wizard = Etsource::Wizard.new(@form.code)
    end

  protected

    def assign_area_code
      @area_code = params[:area_code] || 'nl'
    end

    # Assign a area_code to a scenario, so @gql properly loads
    def assign_scenario
      Current.scenario = ApiScenario.new(ApiScenario.default_attributes.merge :area_code => @area_code)
      @gql = Current.scenario.gql
      @gql.prepare
    end

    def default_url_options
      {:area_code => @area_code}
    end

  end
end
