module Gql

class StoredProcedure

  def self.execute(query)
    @instance ||= new()
    if query.is_a?(::Gquery)
      query = query.query
    end
    @instance.send(query)
  end

  # add all the attributes and methods that are modularized in stored_procedure/
  # loads all the "open classes" in stored_procedure
  Dir["app/models/gql/stored_procedure/*.rb"].sort.each {|file| require_dependency file }
end

end
