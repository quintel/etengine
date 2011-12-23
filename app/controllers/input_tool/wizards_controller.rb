module InputTool
  class WizardsController < BaseController
    before_filter :assign_area_code
    before_filter :assign_scenario

    def assign_area_code
      @area_code = params[:area_code] || 'nl'
    end

    # Assign a area_code to a scenario, so Current.gql properly loads
    def assign_scenario
      Current.scenario = Scenario.new(Scenario.default_attributes.merge :country => @area_code)
    end

    def default_url_options
      {:area_code => @area_code}
    end

    def index
      @saved_wizards = SavedWizard.area_code(@area_code)
      @stored_wizard_codes = @saved_wizards.map(&:code)
      @new_wizard_codes = Etsource::Wizard.new.list - @stored_wizard_codes
    end

    def show
    end

    def destroy
      @form = SavedWizard.find(params[:id])
      @form.destroy
      redirect_to input_tool_wizards_url
    end


    def new
      @form = InputTool::SavedWizard.new(:code => params[:code], :area_code => @area_code)
    end

    def create
      @code = params[:input_tool_saved_wizard][:code]
      @form = InputTool::SavedWizard.new(:code => @code, :area_code => @area_code)
      @form.values = params[@code]
      if @form.save
        redirect_to edit_input_tool_wizard_path(:id => @form.to_param)
      else
        render :action => 'new'
      end
    end

    def update
      @form = SavedWizard.find(params[:id])
      if @form.update_attributes(:values => params[@form.code])
        flash[:notice] = 'success'
        redirect_to edit_input_tool_wizard_path(id: @form)
      else

        render :action => 'edit'
      end
    end

    def edit
      @form = SavedWizard.find(params[:id])
    end
  end
end