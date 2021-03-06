# This is needed for caching to properly work.
#
# Marshal.load is a C-method built into Ruby; because it's so low-level, it
# bypasses the full classloading chain in Ruby, in particular the #const_missing
# hook that Rails uses to auto-load classes as they're referenced. This monkey
# patch catches the generated exceptions, parses the message to determine the
# offending constant name, loads the constant, and tries again.
#
# This solution is adapted from here:
# http://kballcodes.com/2009/09/05/rails-memcached-a-better-solution-to-the-undefined-classmodule-problem/
#
# class <<Marshal
#   def load_with_rails_classloader(*args)
#     begin
#       load_without_rails_classloader(*args)
#     rescue ArgumentError, NameError => e
#       if e.message =~ %r(undefined class/module)
#         const = e.message.split(' ').last
#         const.constantize
#         retry
#       else
#         raise(e)
#       end
#     end
#   end

#   alias_method_chain :load, :rails_classloader
# end

class Numeric
  # rescue from 0.0/0.0 or 0.0/1.0 calculation errors
  def rescue_nan(with = 0.0)
    self
  end
end

class Float
  # rescue from 0.0/0.0 or 0.0/1.0 calculation errors
  # (0.0 / 0.0).rescue_nan
  # => 0.0
  def rescue_nan(with = 0.0)
    finite? ? self : with
  end
  def as_json(options = nil) finite? ? self : 'null' end #:nodoc:
end


class String
  def cjust(string, lft, rgt)
    a,b = self.split(string)
    if b
      a.rjust(lft) + string + b.ljust(rgt)
    else
      self
    end
  end
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
