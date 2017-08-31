class ConverterPositions
  DEFAULT_Y = {
    :households   =>  100,
    :industry     => 9000,
    :transport    => 3500,
    :agriculture  => 5300,
    :energy       => 3000,
    :other        => 8300,
    :environment  =>  100,
    :buildings    => 6100,
    :neighbor     =>  100
  }.with_indifferent_access

  FILL_COLORS = {
    :households   => '#E69567',
    :industry     => '#CCCCCC',
    :transport    => '#FFD700',
    :agriculture  => '#B3CF7B',
    :energy       => '#ADD8E6',
    :other        => '#7BABBA',
    :environment  => '#32CD32',
    :buildings    => '#FF6666',
    :neighbor     => '#87CEEB',
    :bunkers      => '#5CD0A5'
  }.with_indifferent_access

  def initialize(path)
    @path = Pathname.new(path)
  end

  def find(converter)
    data[converter.key] || { x: 100, y: DEFAULT_Y[converter.sector_key] }
  end

  def update(with)
    with.each do |key, positions|
      positions = positions.symbolize_keys
      data[key.to_sym] = { x: positions[:x].to_i, y: positions[:y].to_i }
    end

    File.write(@path, YAML.dump(data))
  end

  def to_yaml
    YAML.dump(data)
  end

  #######
  private
  #######

  def data
    @data ||= YAML.load_file(@path)
  end
end
