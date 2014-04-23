##
# A Gquery holds a specific GQL query. It mainly consists of:
# - key: other gqueries can embed this query using the key. E.g. SUM(QUERY(foo),QUERY(bar))
# - query: the GQL query in a human readable plain text format.
#
class Gquery
  include InMemoryRecord
  include CommandAttributes

  extend ActiveModel::Naming

  attr_reader   :key
  attr_accessor :description, :file_path, :group_key
  attr_accessor *Atlas::Gquery.attribute_set.map(&:name)

  def initialize(attributes={})
    attributes && attributes.each do |name, value|
      send("#{name}=", value) if respond_to? name.to_sym
    end
  end

  def persisted?
    false
  end

  def self.load_records
    Etsource::Loader.instance.gqueries.each_with_object({}) do |gquery, data|
      data[gquery.key.to_s] = gquery

      if gquery.deprecated_key
        data[gquery.deprecated_key.to_s] = gquery
      end
    end
  end

  GQL_MODIFIERS = %(present future historic stored)
  GQL_MODIFIER_REGEXP = /^([a-z_]+)\:/

  def id
    key
  end

  def key=(new_key)
    new_key && (@key = new_key.to_s)
  end

  def self.get(key)
    super(key.to_s)
  end

  # Public: The GQL::Command which represents the string held in the +query+
  # attribute.
  def command
    @command ||= command_for(:query)
  end

  def converters?
    unit == 'converters'
  end

  def cacheable?
    !converters?
  end

  def dashboard?
    key.include?('dashboard_')
  end

  def output_element?
    group_key.include?("output_elements")
  rescue => e
    false
  end

  def gql_modifier
    @gql_modifier ||= query.match(GQL_MODIFIER_REGEXP).andand.captures.andand.first
  end

  def self.group_keys
    NastyCache.instance.fetch_cached("Gquery.groups") do
      Gquery.all.map(&:group_key).uniq
    end
  end

  # GQL syntax highlighting uses this array
  def self.cached_keys
    Rails.cache.fetch('gquery_keys') do
      self.all.map(&:key)
    end
  end

  def self.name_or_query_contains(q)
    all.select do |g|
      [:key, :query, :deprecated_key].any? do |attr|
        g.send(attr).to_s.include? q
      end
    end
  end

  def self.contains(q)
    all.select {|g| g.query.to_s.include? q }
  end

  def <=>(other)
    self.key <=> other.key
  end
end
