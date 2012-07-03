# == Schema Information
#
# Table name: gqueries
#
#  id              :integer(4)      not null, primary key
#  key             :string(255)
#  query           :text
#  name            :string(255)
#  description     :text
#  created_at      :datetime
#  updated_at      :datetime
#  not_cacheable   :boolean(1)      default(FALSE)
#  unit            :string(255)
#  deprecated_key  :string(255)
#  gquery_group_id :integer(4)
#

##
# A Gquery holds a specific GQL query. It mainly consists of:
# - key: other gqueries can embed this query using the key. E.g. SUM(QUERY(foo),QUERY(bar))
# - query: the GQL query in a human readable plain text format.
#
#
class Gquery < ActiveRecord::Base
  include InMemoryRecord

  def self.load_records
    h = {}
    Etsource::Loader.instance.gqueries.each do |gquery|
      h[gquery.key] = gquery
      h[gquery.lookup_id.to_s] = gquery
      h[gquery.deprecated_key] = gquery
    end
    h
  end

  GQL_MODIFIERS = %(present future historic stored)
  GQL_MODIFIER_REGEXP = /^([a-z_]+)\:/

  validates_presence_of :key
  validates_presence_of :query
  validates_exclusion_of :key, :in => %w( null undefined ), :on => :create, :message => "extension %s is not allowed"

  belongs_to :gquery_group

  scope :by_groups, lambda{|*gids|
    gids = gids.compact.reject(&:blank?)
    where(:gquery_group_id => gids.compact) unless gids.compact.empty?
  }

  after_initialize do |gquery|
    self.key = self.key.strip if self.key
  end

  def id
    lookup_id
  end

  def lookup_id
    @lookup_id ||= Hashpipe.hash(key)
  end

  def group_key
    gquery_group.try :group_key
  end

  # As a tribute to Ed Posnak I leave the following comment where it is.
  # ejp- cleaning algorithm is encapsulated in Gql:Gquery::Preparser


  # Returns the sanitized query string as a lambda.
  #
  # @example
  #   q = Gquery.all.first.rubel
  #   gql.present.query( q )
  #
  # @return [lambda]
  #
  def rubel
    @rubel_proc ||= self.class.rubel_proc(query)
  end

  # Returns the sanitized gql query string as a lambda.
  # It passes it through the Rubel sandbox for another security
  # layer (make it harder to access classes and modules).
  #
  # @example
  #   q = Gquery.rubel_proc("SUM(1,2)")
  #   # => lambda { SUM(1,2) }
  #   gql.present.query( q )
  #   # => 3
  #
  # @return [lambda]
  #
  def self.rubel_proc(str)
    @rubel ||= Gql::Grammar::Sandbox.new
    @rubel.sanitized_proc(convert_to_rubel!(str.dup))
  end

  # sanitize query string. removes gquery related stuff
  # like future/present: gql modifier strings.
  def self.convert_to_rubel!(string)
    string.gsub!(/[\n\s\t]/, '')
    string.gsub!(/^[a-z]+\:/,'')
    string
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
    gquery_group.group_key.include?("output_elements")
  rescue => e
    false
  end

  def gql_modifier
    @gql_modifier ||= query.match(GQL_MODIFIER_REGEXP).andand.captures.andand.first
  end

  # GQL syntax highlighting uses this array
  def self.cached_keys
    Rails.cache.fetch('gquery_keys') do
      self.all.map(&:key)
    end
  end

  def self.name_or_query_contains(q)
    all.select do |g|
      [:name, :query, :deprecated_key].any? do |attr|
        g.send(attr).to_s.include? q
      end
    end
  end

  def self.contains(q)
    all.select {|g| g.query.to_s.include? q }
  end
end
