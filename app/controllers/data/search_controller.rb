class Data::SearchController < Data::BaseController
  skip_before_filter :initialize_gql, :only => [:index]

  def index
    respond_to do |format|
      format.js {}
      format.html do
        if search = params[:search]
          if gquery = Gquery.get(search.strip)
            redirect_to data_gquery_path(id: gquery.key)
          elsif Etsource::Loader.instance.graph.converter(search)
            redirect_to data_converter_path(id: search)
          end
        else
          redirect_to :back
        end
      end
    end
  end

end
