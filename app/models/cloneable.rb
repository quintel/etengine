# fozen_string_literal: true

# Module to help with deep cloning data structures
module Cloneable
  # Internal: Deep clones an object by serialising and deserialising it.
  # Could be optimised in the future by using MessagePack instead of Marshal
  #
  # If cloning with Marshal fails, fallback on ruby's less reliable deep_dup
  #
  # Returns a clone of the object
  def deep_clone(obj)
    Marshal.load(Marshal.dump(obj))
  rescue TypeError
    obj.deep_dup
  end

  def create_clone
    deep_clone(self)
  end
end
