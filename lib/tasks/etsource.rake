namespace :etsource do
  namespace :gqueries do
    task :export => :environment do
      Etsource::Gqueries.new.export
    end

    task :import => :environment do
      Etsource::Gqueries.new.import!
    end
  end
end