module InMemoryRecord
  extend ActiveSupport::Concern

  def save(*args)
    raise "InMemoryRecord: Object#save not allowed"
  end

  module ClassMethods
    def create(*args)
      raise "InMemoryRecord: Object.create not allowed"
    end

    def all
      records.values
    end

    def records
      @records ||= load_records
    end

    def get(key)
      records[key]
    end

    def add(obj)
      records[obj.lookup_id] = obj
      obj
    end
  end
end
