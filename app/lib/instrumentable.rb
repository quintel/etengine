module Instrumentable

  def instrument(*args)
    ActiveSupport::Notifications.instrument(*args) do
      yield
    end
  end

end