class Numeric
  # rescue from 0.0/0.0 or 0.0/1.0 calculation errors
  # (0.0 / 0.0).rescue_nan
  # => 0.0
  def rescue_nan(with = 0.0)
    finite? ? self : with
  end
end

class Float
  def as_json(options = nil) finite? ? self : NilClass::AS_JSON end #:nodoc:
end


# Extend Hash with recursive merging abilities
class Hash
  # Merges self with another hash, recursively.
  #
  # This code was lovingly stolen from some random gem:
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  def deep_merge(hash)
    target = dup

    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end

      target[key] = hash[key]
    end

    target
  end

  # From: http://www.gemtacular.com/gemdocs/cerberus-0.2.2/doc/classes/Hash.html
  # File lib/cerberus/utils.rb, line 42
  def deep_merge!(second)
    second.each_pair do |k,v|
      if self[k].is_a?(Hash) and second[k].is_a?(Hash)
        self[k].deep_merge!(second[k])
      else
        self[k] = second[k]
      end
    end
  end
end


module Kernel
# http://www.ruby-forum.com/topic/75258
private
  def caller_method
    caller[1] =~ /`([^']*)'/ and $1
  end
end
