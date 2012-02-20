# ------ Examples -------------------------------------------------------------
#
#     et = Etsource::Dataset.new('nl')
#     et.import # => Qernel::Dataset for country 'nl'
#
#
#
# ------ DEBT: Refactor this --------------------------------------------------
#
# The YML parsing and import methods really deserve an own class. Right now it's
# a bit a mess.. This should be fixed soon.
#

module Etsource
  class Dataset
    attr_reader :country
    
    def initialize(country)
      # DEBT: @etsource is only used for the base_dir, can be solved better.
      @etsource = Etsource::Base.instance
      @country  = country
    end

    # Importing dataset and convert into the Qernel::Dataset format.
    # The yml file is a flat (no nested key => values) hash. We move it to a nested hash
    # and also have to convert the keys into a numeric using a hashing function (FNV 1a),
    # the additional nesting of the hash, and hashing ids as strings are mostly for 
    # performance reasons.
    # 
    def import
      ::Etsource::Dataset::Import.new(country).import
    end

    def export
      all_countries = Area.all.map(&:region_code)
      all_countries.each{|c| ::Etsource::Dataset::Export.new(c).export }
    end

    def self.region_codes
      Dir.glob(Etsource::Base.instance.base_dir+"/datasets/[a-z]*").map{|folders| folders.split("/").last }
    end

  end
end