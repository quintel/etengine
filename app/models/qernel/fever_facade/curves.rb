# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Looks up profiles and curves for use within Fever participants. Permits
    # the use of dynamic curves as defined in ETSource. Otherwise falls back to
    # first attempting to load from the heat CurveSet and finally from the
    # dataset load profile directory.
    class Curves < Causality::Curves
    end
  end
end
