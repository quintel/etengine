# TODO: Get rid of this - PZ Wed 11 May 2011 09:56:29 CEST

module EtmFixtures

  # load consistent set of queries (including those in policy_goals and constraints)
  require 'active_record/fixtures'
  def load_carriers
    fixtures_path = "spec/fixtures"
    Carrier.delete_all
    Fixtures.create_fixtures(fixtures_path, File.basename('carriers', '.*'))
    Qernel::ConverterApi.create_methods_for_each_carrier(::Carrier.all.map(&:key))
  end
end