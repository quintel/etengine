namespace :etsource do
  namespace :gqueries do
    task :export => :environment do
      Etsource::Gqueries.export
    end

    task :import => :environment do
      Etsource::Gqueries.import!
    end
  end
end