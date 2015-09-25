class Data::MeritController < Data::BaseController
  layout 'application'

  def index
  end

  def download
    contents = CSV.generate do |csv|
      merit_order.load_curves.each { |row| csv << row }
    end

    send_data(contents, type: 'text/csv', filename: 'load_curves.csv')
  end

  def prices
    contents = CSV.generate do |csv|
      merit_order.price_curve.each { |row| csv << [row] }
    end

    send_data(contents, type: 'text/csv', filename: 'prices.csv')
  end

  private

  def merit_order
    @mo ||= Qernel::Plugins::MeritOrder.new(@gql.future_graph).order.calculate
  end

end
