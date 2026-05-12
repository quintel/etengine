# frozen_string_literal: true

module Etsource
  # Raised when a dataset cannot be found in ETSource.
  #
  # This error is raised when attempting to load a dataset that doesn't exist,
  # either because the Atlas dataset key is invalid or the .pack file is missing.
  class DatasetNotFoundError < StandardError
    attr_reader :dataset_key

    def initialize(dataset_key, message = nil)
      @dataset_key = dataset_key
      super(message || "Dataset '#{dataset_key}' not found in ETSource")
    end
  end
end
