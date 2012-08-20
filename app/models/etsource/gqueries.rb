module Etsource
  class Gqueries
    VARIABLE_PREFIX = '-'
    FILE_SUFFIX = 'gql'

    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def export
      base_dir = "#{@etsource.base_dir}/gqueries"
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
      gqueries
    end

    def gqueries
      gqueries = []
      groups = gquery_groups

      Dir.glob("#{base_dir}/**/*.#{FILE_SUFFIX}").each do |f|
        tokens = f.gsub(base_dir+"/", '').split('/')
        # the group name concatenates the directory names
        group_key = tokens[0..-2].join('_').gsub(' ', '_') rescue nil
        gquery = from_file(f)

        gquery.gquery_group = groups[group_key]
        gqueries << gquery
      end
      gqueries
    end

    def gquery_groups
      # make something like an identity map, so that there can be no duplicates
      # of groups around.
      @gquery_groups_identity_map ||= {}
      gquery_groups = {}

      Dir.glob("#{base_dir}/**/*.#{FILE_SUFFIX}").each do |f|
        tokens = f.gsub(base_dir+"/", '').split('/')
        # the group name concatenates the directory names
        group_key = tokens[0..-2].join('_').gsub(' ', '_') rescue nil
        @gquery_groups_identity_map[group_key] ||= GqueryGroup.new(:group_key => group_key)
        gquery_groups[group_key] = @gquery_groups_identity_map[group_key]
      end
      gquery_groups
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
      key = f.split('/').last.split('.').first.strip
      txt = File.read(f)


      comment_lines  = []
      variable_lines = []
      query_lines    = []
      txt.lines.each do |line|
        case line
        when /^#/ then comment_lines << line
        when /^#{VARIABLE_PREFIX}.*=/ then variable_lines << line
        else query_lines << line
        end
      end

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
        :deprecated_key => variables['deprecated_key'],
        :file_path => f
      )
    end

    def group_key(g)
      g.group_key.downcase.gsub(/\s/, '_') rescue 'other'
    end

    def base_dir
     "#{@etsource.export_dir}/gqueries"
    end

  end
end
