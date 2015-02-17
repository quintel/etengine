class Data::MeritController < Data::BaseController
  layout 'application'

  def index
  end

  def download

    order = Qernel::Plugins::MeritOrder.new(@gql.future_graph).order.calculate

    contents = CSV.generate do |csv|
      order.load_curves.each { |row| csv << row }
    end

    send_data(contents, type: 'test/csv', filename: 'load_curves.csv')

  end

end
