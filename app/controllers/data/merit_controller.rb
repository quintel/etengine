class Data::MeritController < Data::BaseController
  layout 'application'

  def index
  end

  def download

    moi = Qernel::Plugins::MeritOrder::MeritOrderInjector.new(@gql.future_graph, true)
    moi.setup_items
    moi.send(:calculate_merit_order)

    contents = CSV.generate do |csv|
      moi.m.load_curves.each do |row|
        csv << row
      end
    end

    send_data(contents, type: 'test/csv', filename: 'load_curves.csv')

  end

end
