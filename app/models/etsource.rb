module Etsource
  ETSOURCE_DIR = 'etsource'

  class Commit
    attr_reader :commit

    def initialize(commit)
      @git = Git.open('etsource')
      @commit = @git.gcommit(commit)
      @git.checkout(commit)
    end

    def import!
      Gquery.transaction do 
        GqlTestCases.new.import!
        Gqueries.new.import!
      end
      # DEBT fix this properly
      `curl http://beta.et-model.com/pages/refresh_gqueries > /dev/null`
    end
  end
  
  class GqlTestCases
    def import!
      GqlTestCase.delete_all
      import
    end
    
    def import
      base_dir = "#{ETSOURCE_DIR}/test_suites"
      Dir.glob("#{base_dir}/**/*.js").each do |f|
        key = f.split('/').last.split('.').first
        GqlTestCase.create(:name => key, :instruction => File.read(f))
      end
    end
  end

  class Gqueries
    VARIABLE_PREFIX = '-'
    FILE_SUFFIX = 'gql'
    
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
        File.open("#{path}/#{gquery.key}.#{FILE_SUFFIX}", 'w') do |f|
          f << to_file(gquery)
        end
      end
    end

    def import
      base_dir = "#{ETSOURCE_DIR}/gqueries"
      groups = GqueryGroup.all.inject({}) {|hsh,g| hsh.merge group_key(g) => g}
      
      gqueries = []
      Dir.glob("#{base_dir}/**/*.#{FILE_SUFFIX}").each do |f|
        group_key, rest = f.gsub(base_dir+"/", '').split('/')
        gquery = from_file(f)
        groups[group_key] ||= GqueryGroup.create(:group_key => group_key)
        gquery.gquery_groups << groups[group_key]
        gqueries << gquery
      end
      Gquery.import gqueries
    end

  #protected
    def to_file(gquery)
      commented_description = "# #{gquery.description.to_s.strip.gsub("\n", "\n# ")}\n\n"
      unit = gquery.unit.to_s.downcase.strip.gsub(' ', '_')
      unit = 'boolean' if unit.include?('true')
      
      out = commented_description
      out += "#{VARIABLE_PREFIX} deprecated_key = #{gquery.deprecated_key}\n" if gquery.deprecated_key.present?
      out += "#{VARIABLE_PREFIX} unit = #{unit}\n\n"
      out += gquery.query
      out
    end
    
    def from_file(f)
      key = f.split('/').last.split('.').first
      txt = File.read(f)
      
      comment_lines  = txt.lines.select{|l| l.match(/^#/)}
      variable_lines = txt.lines.select{|l| l.match(/^#{VARIABLE_PREFIX}/)}
      query_lines    = txt.lines.reject{|l| l.match(/^[#{VARIABLE_PREFIX}#]/)}
      
      # the unit and deprecated_key (optional) is defined inside the comment-block:
      #   # deprecated_key: foo
      #   # unit: kg
      variables = variable_lines.inject({}) do |hsh, l|
        begin
          k,v = l.match(/-\s*([\w_]+)\s+=\s+(.+)\n/).captures
          hsh.merge k.strip => v.strip
        rescue => e
          hsh
        end
      end
      description = comment_lines.map{|l| l[1..-1].strip }.join("\n")
      query = query_lines.join("").strip
      
      Gquery.new(
        :key => key, 
        :description => description, 
        :query => query, 
        :unit => variables['unit'], 
        :deprecated_key => variables['deprecated_key']
      )
    end
    
    def group_key(g)
      g.group_key.downcase.gsub(/\s/, '_') rescue 'other'
    end
  end
end