module Gql::UpdateInterface

##
# include this module if a CommandBase is responsible
# based on the regexp defined in the MATCHER constant.
#
module ResponsibleByMatcher
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods

    ##
    # Checks passed key if it matches with the Regexp defined in MATCHER.
    #
    # @param key [String] 
    # @return [true,false]
    #
    def responsible?(key)
      key.match(self.const_get(:MATCHER))
    end

  end
end

end