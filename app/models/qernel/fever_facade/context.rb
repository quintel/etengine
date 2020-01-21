# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Encapsulates objects useful to the Fever calculation.
    Context =
      Struct.new(:plugin, :graph) do
        delegate :curves, to: :plugin
      end
  end
end
