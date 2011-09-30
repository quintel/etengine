module Etsource
  ETSOURCE_DIR = 'etsource'
  
  class Gqueries
    def import!
      Gquery.transaction do
        Gquery.delete_all
        GqueryGroup.delete_all
        import
        Rails.cache.clear
        system("touch tmp/restart.txt")
      end
    end

    def export
      base_dir = "#{ETSOURCE_DIR}/gqueries"
      Gquery.includes(:gquery_groups).all.each do |gquery|
        group = group_key(gquery.gquery_groups.first)
        path = [base_dir, group].compact.join('/')

        FileUtils.mkdir_p(path)
        File.open("#{path}/#{gquery.key}.yml", 'w') do |f|
          f << to_file(gquery)
        end
      end
    end

    def import
      base_dir = "#{ETSOURCE_DIR}/gqueries"
      groups = GqueryGroup.all.inject({}) {|hsh,g| hsh.merge group_key(g) => g}
      
      gqueries = []
      Dir.glob("#{base_dir}/**/*.yml").each do |f|
        group_key, rest = f.gsub(base_dir+"/", '').split('/')
        gquery = from_file(f)
        groups[group_key] ||= GqueryGroup.create(:group_key => group_key)
        gquery.gquery_groups << groups[group_key]
        gqueries << gquery
      end
      Gquery.import gqueries
    end

  protected
    def to_file(gquery)
      commented_description = "# #{gquery.description.to_s.strip.gsub("\n", "\n# ")}\n"
      unit = gquery.unit.to_s.downcase.strip.gsub(' ', '_')
      unit = 'boolean' if unit.include?('true')
      
      out = commented_description
      out += "# unit: #{unit} \n\n"
      out += gquery.query
      out
    end
    
    def from_file(f)
      key = f.split('/').last.split('.').first
      txt = File.read(f)
      
      comment_lines = txt.lines.select{|l| l.match(/^#/)}
      query_lines   = txt.lines.reject{|l| l.match(/^#/)}
      
      # the unit is defined inside the comment-block:
      #   # unit: kg
      unit = comment_lines.last.match(/#\s*unit\:\s*(.+)\n/).captures.first.strip rescue 'undefined'
      
      description = comment_lines[0...-1].map{|l| l[1..-1].strip }.join("\n")
      query = query_lines.join("").strip
      
      Gquery.new(:key => key, :description => description, :query => query, :unit => unit)
    end
    
    def group_key(g)
      g.group_key.downcase.gsub(/\s/, '_') rescue 'other'
    end
  end
end