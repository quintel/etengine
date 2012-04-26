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

  scope :contains, lambda{|search| where("query LIKE ?", "%#{search}%")}
  scope :name_or_query_contains, lambda{|q| where([
     "`key` LIKE :q OR query LIKE :q OR deprecated_key LIKE :q", { :q => "%#{q}%" }
  ])}

  scope :by_name, lambda{|q| where("`key` LIKE ?", "%#{q}%")}

  # This scope will stack the previous by_name scope to allow searching using multiple terms
  scope :by_name_multi, lambda{|q|
    base = self.scoped
    if q.is_a?(String)
      tokens = q.split(' ')
      tokens.each{|t| base = base.by_name(t.strip)}
    end
    base
  }

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

  # As a tribute to Ed Posnak I leave the following comment where it is.
  # ejp- cleaning algorithm is encapsulated in Gql:Gquery::Preparser

  def gql3
    @gql3_proc ||= self.class.gql3_proc(query)
  end

  def self.gql3_proc(str)
    eval("lambda { #{convert_to_gql3!(str.dup)} }")
  end

  def self.convert_to_gql3!(string)
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

end
