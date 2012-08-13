class Qernel::ConverterApi

  def average_cost_per_year
    function(:average_cost_per_year) do
      if total_real_costs && lifetime && lifetime > 0
        total_real_costs / lifetime
      else
        0
      end
    end
  end

end
