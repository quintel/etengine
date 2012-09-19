# Hashpipe creates a 32 bit Fixnum hash of a string. Used for qernel object
# keys so that we can properly lookup data in the dataset. Using fixnums
# instead of string keys decreases the total dataset size and unmarshalling
# time, because our qernel keys are big.
#
# It's using the FNV algorithm from the fnv-gem. This could just as well be
# replaced with the ruby hash method.
#
# @example
#   Hashpipe.hash("some-long-key") => 121234
#   # Removes whitespace!
#   Hashpipe.hash("some  -long -   key  ") => 121234
#
#
class Hashpipe
  include Singleton

  def initialize
    @fnv = FNV.new
  end

  def hash(key)
    @fnv.fnv1a_32(key.to_s.gsub(/\s/, ''))
  end

  def self.hash(key)
    Hashpipe.instance.hash(key)
  end
end
