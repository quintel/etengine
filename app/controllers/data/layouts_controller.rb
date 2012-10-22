class Data::LayoutsController < Data::BaseController
  before_filter :find_models, :only => [:show, :edit]

  helper_method :attributes_for_json

  skip_authorize_resource :only => :show

  def show
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
    end
  end

  def edit
    respond_to do |format|
      format.html { render :layout => 'blueprint_layout' }
      format.json { render :json => result  }
    end
  end

  def update
    if params[:converter_positions].present?
      params[:converter_positions].each do |converter_id,attributes|
        if bcp = ConverterPosition.find_by_converter_id(converter_id)
          bcp.update_attributes attributes
        else
          ConverterPosition.create attributes.merge(:converter_id => converter_id, :blueprint_layout_id => params[:blueprint_layout_id])
        end
      end
    end
    render :text => ''
  end

private
  def result
    unless @result
      @result = {
        'future' => graph_to_json(@gql.future_graph),
        'present' => graph_to_json(@gql.present_graph)
      }
    end
    @result
  end

  def attributes_for_json
    attrs = ['demand', 'primary_demand', 'energy_balance_group']
    attrs << Qernel::ConverterApi::ATTRIBUTES_USED.sort if params[:action] == 'edit'
    attrs.flatten
  end

  def find_models
    @converter_positions = ConverterPosition.all.inject({}) {|hsh, cp| hsh.merge cp.converter_id => cp}
  end

  def graph_to_json(graph)
    graph.converters.inject({}) do |hsh, c|
      attr_hash = attributes_for_json.inject({}) do |h, key|
        v = c.query.send(key)
        h.merge key => auto_number(v)
      end
      hsh.merge c.excel_id => attr_hash
    end
  end

  def auto_number(n)
    self.class.helpers.auto_number(n)
  end

end
