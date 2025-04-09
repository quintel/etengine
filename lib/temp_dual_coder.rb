class TempDualCoder
  require 'yaml'
  require 'msgpack'

  def dump(object)
    object.to_msgpack
  end

  def load(value)
    return {} if value.blank?

    if value.is_a?(String) && value.start_with?('---')
      YAML.safe_load(value, permitted_classes: [Hash, Float, Integer, String, Symbol], aliases: true)
    else
      begin
        MessagePack.unpack(value)
      rescue MessagePack::MalformedFormatError => e
        Rails.logger.error("UserValues decoding error: #{e.message}")
        {}
      end
    end
  end
end
