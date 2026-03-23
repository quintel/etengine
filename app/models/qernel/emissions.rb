module Qernel
  class Emissions

    # ----- Dataset -------------------------------------------------------------

    include DatasetAttributes

    def initialize(**attributes)
      @dataset_key = @key = :emissions_data

      Emissions.dataset_accessors(*attributes.keys)


    end

    # private



    # Set the dataset attributes
  end
end
