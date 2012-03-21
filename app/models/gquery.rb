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
  GQL_MODIFIERS = %(present future historic stored)
  GQL_MODIFIER_REGEXP = /^([a-z_]+)\:/

  validates_presence_of :key
  validates_presence_of :query
  validates_exclusion_of :key, :in => %w( null undefined ), :on => :create, :message => "extension %s is not allowed"

  belongs_to :gquery_group
  
  after_save :reload_cache

  strip_attributes! :only => [:key]

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
  
  # Returns the cleaned query for any given key.
  #
  # @param key [String] Gquery key (see Gquery#key)
  # @return [String] Cleaned Gquery
  #
  def self.get(key)
    query = gquery_hash[key]
    raise Gql::GqlError.new("Gquery.get: no query found with key: #{key}") if query.nil?
    # Check gql_metrics.rb initializer to see what we're doing with this notification
    ActiveSupport::Notifications.instrument("gql.gquery.deprecated", key) if deprecated_gquery_hash[key]
    query
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
    string.gsub!("\n", '')
    string.gsub!(/;([^\)]*)\)/, ';"\1")')
    string.gsub!("[", "(")
    string.gsub!("]", ")")
    string.gsub!(';', ',')
    string.gsub!("\s", '')
    string.gsub!("\t", '')
    string.gsub!(/[a-z]+\:/,'')
    string
  end

  # Memoized gquery hashes
  @@gquery_hash = nil
  @@deprecated_gquery_hash = nil

  def self.gquery_hash
    @@gquery_hash ||= build_gquery_hash
  end
  
  def self.deprecated_gquery_hash
    @@deprecated_gquery_hash ||= build_deprecated_gquery_hash
  end
  
  # DEBT: I added the deprecated key to the gquery hash, otherwise the lookup will fail.
  # I think we should change the way we deal with deprecated keys by creating a
  # brand new gquery with a deprecated flag and that calls the new gquery name.
  # PZ - Thu Oct 20 14:37:53 CEST 2011
  #
  def self.build_gquery_hash
    h = {}
    load_gqueries.each do |gquery| 
      h[gquery.key] = gquery
      h[gquery.id.to_s] = gquery
      h[gquery.deprecated_key] = gquery
    end
    h
  end
  
  # Fast lookup hash to determine whether we're using a deprecated key
  #
  def self.build_deprecated_gquery_hash
    h = {}
    load_gqueries.select{|g| g.deprecated_key.present? }.each do |g| 
      h[g.deprecated_key] = g
    end
    h
  end

  def self.load_gqueries
    # choose here which way you want to load gqueries. from db or from etsource.
    db_gqueries
  end

  def self.etsource_gqueries
    # need a way to assign id, to make this work.
    Etsource::Loader.instance.gqueries
  end

  def self.db_gqueries
    all
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

  # Method to invalidate the memoized gquery_hash.
  #
  def self.reload_cache
    @@gquery_hash = nil
  end

  private
    def reload_cache
      self.class.reload_cache
    end
end
