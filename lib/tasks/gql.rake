namespace :gql do
  task :future => :environment do
    default_gql.future.rubel.pry
  end

  task :present => :environment do
    default_gql.present.rubel.pry
  end

  def default_gql
    Rails.cache.clear
    ApiScenario.default.gql(prepare: true).
      tap{|gql| gql.sandbox_mode = :console}
  end
end