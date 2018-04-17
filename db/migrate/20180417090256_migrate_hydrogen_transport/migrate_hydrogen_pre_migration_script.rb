data = {}

VAGUE_CONSTANT = 13.5211267606

scenarios = Scenario.where(protected: true).where('created_at > ?', Date.today - 1.year)
count = scenarios.count
batch_size = 10

scenarios.find_in_batches(batch_size: batch_size).with_index do |group, batch|
  puts "#{ Time.now } | at batch #{ batch } of #{ count / batch_size }"

  group.each do |scenario|
    next unless scenario.valid?

    begin
      gql = scenario.gql

      data[scenario.id] = {
        number_of_energy_hydrogen_steam_methane_reformer: gql.future.query("V(energy_steam_methane_reformer_hydrogen, number_of_units)"),
        number_of_energy_hydrogen_steam_methane_reformer_ccs: gql.future.query("V(energy_steam_methane_reformer_ccs_hydrogen, number_of_units)")
      }

      number_of_industry_flexibility_p2g_electricity = scenario.user_values[:number_of_industry_flexibility_p2g_electricity]
      number_of_energy_flexibility_p2g_electricity = scenario.user_values[:number_of_energy_flexibility_p2g_electricity]

      if number_of_industry_flexibility_p2g_electricity &&
          number_of_energy_flexibility_p2g_electricity

        data[scenario.id][:number_of_energy_hydrogen_flexibility_p2g_electricity] =
          (number_of_industry_flexibility_p2g_electricity +
          number_of_energy_flexibility_p2g_electricity) / VAGUE_CONSTANT
      end
    rescue TypeError, Gql::CommandError => e
    end
  end
end

File.open("data.json", "w") do |f|
  f.write(data.to_json)
end
