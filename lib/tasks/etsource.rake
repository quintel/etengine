namespace :etsource do
  desc "Validate before pushing an etsource commit."
  task :validate do
    Rake::Task["etsource:validate:keys"].invoke
  end

  namespace :validate do
    desc "Check there is no collision when hashing the keys of graph elements"
    task :keys => :environment do
      puts "** Using: #{Etsource::Base.instance.base_dir}"
      
      hashes = []
      Etsource::Topology.new.each_file do |lines|
        lines.each do |line|
          # extract converter keys for converter lines (;-separated lines)
          line = line.split(";").first.strip
          hashes << Hashpipe.hash(line) if line.present?
        end
      end

      raise "" if hashes.length != hashes.uniq.length
      puts "** No conflicts found for #{hashes.length} hashed keys."
    end
  end


end
