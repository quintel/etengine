# ------ Examples -------------------------------------------------------------
#
#     et = Etsource::Dataset.new('nl')
#     et.import # => Qernel::Dataset for country 'nl'
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

    REGION_CODES = [ 'nl'.freeze, 'de'.freeze ].freeze

    def self.region_codes
      # Temporarily restricting to Netherlands ONLY. Even though dataset files
      # exist in Atlas for the UK and Germany, those are not yet ready for
      # use.
      REGION_CODES
    end
  end
end
