namespace :rename do

  desc "rename all the keys of the user_values with a from, to csv file"
  task user_values: [:environment] do

    @file_name = ENV['file']
    @force     = ENV['force'] && ENV['force'].upcase == "TRUE"

    raise "I need a file" unless ENV['file']

    Scenario.all.each do |scenario|

      puts "Working on Scenario ##{ scenario.id }"
      puts "================================================================="

      old_hash = scenario.user_values

      new_hash = old_hash.clone

      old_hash.each do |key, value|
        unless new_key(key) == key
          puts "* DEPRECATION FOUND: #{ key } --> #{ new_key(key) }"
          new_hash[new_key(key)] = value
          new_hash.delete(key)
        end
      end

      if new_hash == old_hash
        puts "  => No old keys found!\n"
      else
        puts "  => will be updated\n"
        scenario.user_values = new_hash
        scenario.save! if @force
      end

    end

    puts "Nothing happend. Append force=true to update your datasbase" unless @force

  end

  # Helper method: returns the new key for an old key, or, if unknown, returns
  # the same key (than it hasn't changed).
  def new_key(old_key)
    key_store[old_key] || old_key
  end

  # Private method: a (hash) store for the old_keys and new keys
  #
  # Returns a Hash
  def key_store
    @key_store ||= begin
      store = {}
      CSV.foreach(@file_name) do |line|
        old_key, new_key = line

        store[old_key] = new_key
      end
      store
    end
  end

end
