namespace :etsource do
  namespace :gqueries do
    task :export => :environment do
      Etsource::Gqueries.new.export
    end

    task :import => :environment do
      Etsource::Gqueries.new.import!
    end
  end

  namespace :inputs do
    task :export => :environment do
      Etsource::Inputs.new.export
    end

    task :import => :environment do
      Etsource::Inputs.new.import!
    end
  end
end