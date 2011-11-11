module Etsource
  class Graph
    def initialize(etsource)
      @etsource = etsource
    end

    def import!
    end

    def base_dir
      "#{@etsource.base_dir}/topology"
    end

    def import
      ids = []

      converters, slot_lines, link_lines = [], [], []
      
      Dir.glob("#{base_dir}/*.topology").each do |f|
        lines = File.read(f).lines
        converters += lines.select{|l| l =~ /^\[\w+\];/ }.map{|l| Qernel::Converter.import(l) }.group_by(&:code)
        slot_lines += lines.select{|l| l =~ /^\[\w+\]-\(\w+\)/ } # match [ABC0123]-(ADasdf2)
        link_lines += lines.select{|l| l =~ /--\w-->/ } # 
      end
      
    end
    
    def create_converter(l)
    end
  end
end