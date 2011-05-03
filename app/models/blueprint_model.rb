##
# BlueprintModel is a basically a Meta Blueprint, that's sole purpose
# is to group Blueprints with their various versions together. Add a new
# BlueprintModel if you create a fundamentally different graph and not 
# just an updated/improved version of an existing one.
# 
#
# == Developer notes:
#
# Actually the ideal structure would be:
#
#   Blueprint (e.g. ETM Country Blueprint)
#     has_many BlueprintVersion (continuously improved versions of the blueprint)
#
# But as I don't want to interfere with all the legacy code, I introduced
# BlueprintModel. So
# 
#   BlueprintModel (e.g. ETM Country Blueprint)
#     has_many Blueprint (continuously improved versions of the blueprint)
#
# 
class BlueprintModel < ActiveRecord::Base
  has_many :blueprints

  validates_presence_of :title

end

# == Schema Information
#
# Table name: blueprint_models
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime
#
