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

    # records is a hash of key => object
    # there can be multiple keys for one object. 
    # The following keys are removed: nil, ""
    def records
      @records ||= load_records.tap do |records| 
        records.delete(nil)
        records.delete("")
      end
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
