class Data::SearchController < Data::BaseController
  layout 'application'
  skip_before_filter :initialize_gql, :only => [:index]

  def index
    respond_to do |format|
      format.js { render :layout => false}
      format.html do
        if search = params[:search]
          if gquery = Gquery.get(search.strip)
            redirect_to data_gquery_path(id: gquery.key)
          elsif Etsource::Loader.instance.graph.converter(search)
            redirect_to data_converter_path(id: search)
          else
            initialize_gql
            @gqueries = Gquery.all.select{|g| g.key.include?(params[:search])}
            @converters = @gql.present_graph.graph.converters.select!{|c| c.key.to_s.include?(params[:search])}
          end
        end
      end
    end
  end
end
