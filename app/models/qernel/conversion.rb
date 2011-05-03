module Qernel
##
# LEGACY LEGACY LEGACY
#
# it is still used, as we import 'conversions' from the excel files.
# converters create slots based on conversions.
# at some point we should get rid of conversions.
#
class Conversion # < ActiveRecord::Base
  attr_accessor :carrier_id, :input, :output


  # TODO: rrename carrier_id to carrier
  def initialize(carrier_id, input = nil, output = nil)
    self.carrier_id = carrier_id
    self.input = input
    self.output = output
  end

  def carrier
    carrier_id
  end

  def value=(val)
    if val < 0.0
      self.input = self[:input] = val.abs
    elsif val >= 0.0
      self.output = self[:output] = val.abs
    end
  end

  def has_input?
    !self.input.nil?
  end

  def has_output?
    !self.output.nil?
  end

  def inspect
    "<Conversion carrier:#{carrier.key} input:#{input} output:#{output}>"
  end

  def to_s
    "Conversion #{carrier_id}: In: #{input} / Out: #{output}"
  end
end

end
