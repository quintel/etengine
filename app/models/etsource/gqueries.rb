module Etsource
  class Gqueries
    VARIABLE_PREFIX = '-'
    FILE_SUFFIX = 'gql'

    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def import
      gqueries
    end

    def gqueries
      gqueries = []

      Dir.glob("#{base_dir}/**/*.#{FILE_SUFFIX}").each do |f|
        # the group name concatenates the directory names
        tokens = f.gsub(base_dir+"/", '').split('/')
        group_key = tokens[0..-2].join('_').gsub(' ', '_').to_sym rescue nil
        gquery = from_file(f)
        gquery.group_key = group_key
        gqueries << gquery
      end
      gqueries
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

    def base_dir
     "#{@etsource.export_dir}/gqueries"
    end

  end
end
