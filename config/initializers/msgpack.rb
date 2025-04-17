require 'msgpack'

module MessagePack
  class << self
    alias_method :load, :unpack
  end
end
