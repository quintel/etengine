# == Schema Information
#
# Table name: gqueries
#
#  id             :integer(4)      not null, primary key
#  key            :string(255)
#  query          :text
#  name           :string(255)
#  description    :text
#  created_at     :datetime
#  updated_at     :datetime
#  not_cacheable  :boolean(1)      default(FALSE)
#  unit           :string(255)
#  deprecated_key :string(255)
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
  # validates_uniqueness_of :key
  validates_presence_of :query
  # DEBT: Add a validates_format_of :query (e.g. should have at least one a-z)
  validates_exclusion_of :key, :in => %w( null undefined ), :on => :create, :message => "extension %s is not allowed"

  validate :validate_query_parseable
  # belongs_to :gquery_group
  has_and_belongs_to_many :gquery_groups
  after_save :reload_cache

  strip_attributes! :only => [:key]

  scope :containing_converter_key, lambda{|key| where("query LIKE ?", "%#{key.to_s}%") }

  scope :contains, lambda{|search| where("query LIKE ?", "%#{search}%")}
  scope :name_or_query_contains, lambda{|q| where([
     "`key` LIKE :q OR query LIKE :q OR deprecated_key LIKE :q", { :q => "%#{q}%" }
  ])}

  scope :by_name, lambda{|q| where("`key` LIKE ?", "%#{q}%")}
  scope :by_key_or_deprecated_key, lambda{|q| where("`key` = :q OR deprecated_key = :q", :q => q)}

  # Returns the cleaned query for any given key.
  #
  # @param key [String] Gquery key (see Gquery#key)
  # @return [String] Cleaned Gquery
  #
  def self.get(key)
    query = gquery_hash[key]
    raise Gql::GqlError.new("Gquery.get: no query found with key: #{key}") if query.nil?
    query
  end



  ##
  # The GqlParser currently does not work with whitespace.
  # So we remove all whitespace before running the query
  #
  # Note: (sb) Alternatively we could also clean the query
  # in the GQL engine. But then it would run for every (sub)query.
  # Instead we memoize (see self.gquery_hash) the clean queries
  # once and for all, saving us a few milliseconds per request.
  #
  # ejp- cleaning algorithm is encapsulated in Gql:Gquery::Preparser
  def parsed_query
    @parsed_query ||= Gql::QueryInterface::Preparser.new(query).parsed
  end

  @@gquery_hash = nil
  ##
  # Memoize gquery_hash
  #
  def self.gquery_hash
    @@gquery_hash ||= build_gquery_hash
  end

  # DEBT: I added the deprecated key to the gquery hash, otherwise the lookup will fail.
  # I think we should change the way we deal with deprecated keys by creating a
  # brand new gquery with a deprecated flag and that calls the new gquery name.
  # PZ - Thu Oct 20 14:37:53 CEST 2011
  def self.build_gquery_hash
    benchmark("** Loading Gquery.build_gquery_hash") do
      self.all.inject({}) do |hsh, gquery|
        hsh.merge(gquery.key => gquery, gquery.id.to_s => gquery, gquery.deprecated_key => gquery)
      end
    end
  end

  def converters?
    unit == 'converters'
  end

  def cacheable?
    !converters?
  end

  def gql_modifier
    @gql_modifier ||= query.match(GQL_MODIFIER_REGEXP).andand.captures.andand.first
  end

  def query_cleaned
    Gql::QueryInterface::Preparser.new(query).clean
  end

  private
    ##
    # Method to invalidate the memoized gquery_hash.
    #
    def reload_cache
      @@gquery_hash = nil
    end

    def validate_query_parseable
      if !Gql::QueryInterface::Preparser.new(self[:query]).valid?
        errors.add(:query, "cannot be parsed")
        false
      else
        true
      end
    end
end
