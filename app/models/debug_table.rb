class DebugTable
  def initialize(objects, arguments, format = :txt)
    @objects   = objects
    @arguments = arguments
    @format    = format
  end

  def to_s
    send("to_#{ @format }")
  end

  def to_txt
    @txt ||= data.to_table(first_row_is_head: true).to_s
  end

  def to_tsv
    @tsv ||= data.map { |row| row.join("\t") }.join("\n")
  end

  def to_csv
    @csv ||= data.map { |row| row.join(",") }.join("\n")
  end

  def data
    return @data if @data

    rows = [[*@arguments]]

    rows += @objects.flatten.uniq.map do |obj|
      @arguments.map do |argument|
        begin
          obj = obj.query if obj.respond_to?(:query)
          if argument.respond_to?(:call)
            obj.instance_eval(&argument)
          else
            obj.instance_eval(argument.to_s)
          end
        rescue => e
          'error'
        end
      end
    end

    @data = rows
  end
end # DebugTable
