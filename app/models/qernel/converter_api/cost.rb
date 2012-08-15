class Qernel::ConverterApi

  def average_cost_per_year
    function(:average_cost_per_year) do
      total_real_costs / lifetime rescue 0
    end
  end

end
