class ConverterPosition

  DEFAULT_Y_BY_SECTOR = {
    :households   =>  100,
    :industry     => 9000,
    :transport    => 3500,
    :agriculture  => 5300,
    :energy       => 3000,
    :other        => 8300,
    :environment  => 100,
    :buildings    => 6100,
    :neighbor     =>  100
  }.with_indifferent_access

  FILL_COLORS_BY_SECTOR = {
    :households   => '#E69567',
    :industry     => '#CCCCCC',
    :transport    => '#FFD700',
    :agriculture  => '#B3CF7B',
    :energy       => '#ADD8E6',
    :other        => '#FF6666',
    :environment  => '#32CD32',
    :buildings    => '#FF6666',
    :neighbor     => '#87CEEB'
  }.with_indifferent_access

  attr_reader :key, :x, :y

  def initialize(attr)
    @key = attr[:key]
    @x   = attr[:x]
    @y   = attr[:y]
  end

  def fill_color(converter)
    if converter && converter.sector_key
      FILL_COLORS_BY_SECTOR[converter.sector_key]
    else
      '#eee'
    end
  end

  def stroke_color
    '#999'
  end

  def x_or_default
    x || 100
  end

  def y_or_default(converter)
    y || DEFAULT_Y_BY_SECTOR[converter.sector_key] || 100
  end

  class << self

    def find(key)
      all.select { |cp| cp.key == key }.first
    end

    # Returns all the converter positions from file and memoized it
    def all
      @all ||= begin
        file_path = Rails.root.join('config/converter_positions.yml')

        YAML.load_file(file_path).map do |key, value|
          new({ key: key, x: value[:x], y: value[:y] })
        end
      end
    end

  end
end
