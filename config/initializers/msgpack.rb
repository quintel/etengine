require 'msgpack'

module MessagePack
  class << self
    alias_method :load, :unpack
    alias_method :dump,  :pack
  end
end
