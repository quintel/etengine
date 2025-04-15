# frozen_string_literal: true

module Scenario::MessagePackArrayCoder
  def self.dump(value)
    value.to_msgpack
  end

  def self.load(value)
    return [] if value.blank?
    MessagePack.unpack(value)
  rescue
    []
  end
end
