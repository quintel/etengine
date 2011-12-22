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
