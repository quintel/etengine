desc 'Generates list converter keys and demands from a static.yml file'
task :generate_key_demand_file => [:environment] do
  path              = ENV['path']
  output_file_name  = 'node_demand.txt'

  unless path && !path.blank?
    puts 'Please specify: path=<path_to_file/filename>'
    exit
  end

  input_file = File.open(path.to_s,'r')  
  output_file = File.open(output_file_name,'w')

  input_file.each do |l|

      if l[0,3] == "  :"
        key_line = l unless l.include? '@' or l.include? 'child_share'
        next if key_line.nil?

        key = key_line.gsub!(%r{:},"").chomp!
        print "#{key}"
        output_file.write("#{key}")
      else
        demand_line = l if l.include? ':demand:'
        next if demand_line.nil?

        demand = demand_line.gsub(%r{:demand: },"").to_f
        print " = #{demand}\n"
        output_file.write(" = #{demand}\n")
      end

  end

  output_file.close()

  puts "\n\nSuccessfully wrote keys and demands to ./#{output_file_name}"
end