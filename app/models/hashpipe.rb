class Hashpipe
  include Singleton

  def initialize
    @fnv = FNV.new
  end

  def hash(key)
    @fnv.fnv1a_32(key.to_s)
  end

  def self.hash(key)
    Hashpipe.instance.hash(key).tap{|i| puts "#{key} : #{i}"}
  end
end
