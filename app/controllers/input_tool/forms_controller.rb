module InputTool
  class FormsController < BaseController

    def index
      @forms = Form.all
      @existing_form_codes = @forms.map(&:code)
      @new_form_codes = Etsource::Forms.new.list - @existing_form_codes
    end
    
    def show

    end

    def destroy
      @form = Form.find(params[:id])
      @form.destroy
      redirect_to input_tool_forms_url
    end


    def new
      @code = params[:code]
      @form = InputTool::Form.new(:code => @code, :area_code => 'nl')
      @value_box = ValueBox.area('nl')
    end

    def create
      @code = params[:input_tool_form][:code]
      @form = InputTool::Form.new(:code => @code, :area_code => 'nl')
      @form.values = params[@code]
      if @form.save
        redirect_to edit_input_tool_form_path(:id => @form.to_param)
      else
        render :action => 'new'
      end
    end

    def update
      @form = Form.find(params[:id])
      if @form.update_attributes(:values => params[@form.code])
        flash[:notice] = 'success'
        redirect_to edit_input_tool_form_path(id: @form)
      else

        render :action => 'edit'
      end
    end

    def edit
      @form = Form.find(params[:id])
      @value_box = ValueBox.area('nl')
    end
  end
end