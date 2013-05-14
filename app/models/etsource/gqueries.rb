module Etsource
  class Gqueries
    VARIABLE_PREFIX = '-'
    FILE_SUFFIX = 'gql'

    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    def import
      ETSource::Gquery.all.map do |gquery|
        Gquery.new(
          :key =>            gquery.key.to_s,
          :description =>    gquery.description,
          :query =>          gquery.query,
          :unit =>           gquery.unit,
          :deprecated_key => gquery.deprecated_key,
          :file_path =>      gquery.path
        )
      end
    end

  end
end
