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
      # self.name => self.class.name 
      EtCache.instance.fetch("#{self.name}#all") do
        records.values.uniq
      end
    end

    # records is a hash of key => object
    # there can be multiple keys for one object. 
    # The following keys are removed: nil, ""
    def records
      EtCache.instance.fetch("#{self.name}#records") do
        load_records.tap do |records| 
          records.delete(nil)
          records.delete("")
        end
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
