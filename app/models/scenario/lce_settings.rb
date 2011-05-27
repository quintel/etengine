# When you burn coal, CO2 and other greenhouse gasses are emitted. However, when 
# the coal is dug up from the earth (also called 'Gaia' or 'Mother Earth' btw), 
# then also some gasses get emitted. During transport, gasses are also emitted. 
# We wanna take these emissions into account as well in the model. This is especially 
# relevant in the discussion about nuclear energy. Some experts claim that nuclear 
# energy emits a lot of CO2 while it's begin dug up, transported and processed.
# 
# These emissions vary per type of carrier (obviously), but also per source of 
# carrier. E.g. coal dug up in China emit more than coal dug up in South Africa.
#
# The life cycle steps are:
# - Exploration
# - Extraction
# - Treatment
# - Transportation
# - Conversion (Hey! That's what we already do in the model!)
# - Waste treatment 
#
#
# == Use
#
# Pass a lce_settings hash to the scenario and it will generate update_statements
# for that scenario.
#
# E.g. 
#
#   Current.scenario.lce_settings = {
#     :coal => {
#       :exploration => {:ch => 1.0},
#       :extraction => {:ch => 0.8, :de => 0.2 }
#     }
#   }
#
# === As URL Parameters
#
#   settings[lce_settings][carrier_key][exploration][ch]=1.0&
#   settings[lce_settings][carrier_key][extraction][de]=1.0
#
class Scenario < ActiveRecord::Base

  # Serialize the settings hash when storing in db.
  serialize :lce_settings

  class LifeCycleEmission
    ##
    # Set @settings_hash by calling self.settings
    #
    def initialize(param = nil)
      self.settings = param
    end

    ##
    # Returns a deep clone of the settings hash.
    #
    # @return [HashWithIndifferentAccess]
    #     A deep clone of the settings.
    #
    # @untested 2011-02-22 seb
    #
    def settings
      Marshal.load(Marshal.dump(@settings_hash))
    end

    ##
    # Replaces the settings with the parameter.
    #
    # @untested 2011-02-22 seb
    #
    def settings=(param)
      hsh = case param
        when String then YAML::load(param)
        when Hash   then param
        else {}
      end
      @settings_hash = hsh.with_indifferent_access
    end

    ##
    # The settings_hash as YAML for storing in a db-column
    #
    # @return [String]
    #     The settings_hash as YAML for storing in a db-column
    #
    def to_yaml
      settings.to_yaml
    end

    ##
    # Gql update statements
    #
    #
    def update_statements
      {'carriers' => update_statements_for_lce}
    end

  private
    ## 
    #
    #
    def update_statements_for_lce
      hsh = {}
      lce_settings = self.settings
      lce_settings.each do |carrier_key, updates|
        updates.each do |carrier_attr,values|
          hsh[carrier_key.to_s] = {} if hsh[carrier_key.to_s].nil?
          hsh[carrier_key.to_s]["#{carrier_attr}_value"] = values.map(&:last).sum
        end
      end
      hsh
    end
  end

  def lce
    @lce ||= LifeCycleEmission.new(self[:lce_settings])
  end

  ##
  # Holds all values chosen by the user for life_cycle settings. 
  #
  # @untested 2010-11-30 seb
  #
  def lce_settings
    lce.settings
  end

  ##
  # Sets the lce_settings and updates the db-column.
  # 
  # @untested 2010-12-22 jape
  #    
  def lce_settings=(values)
    lce.settings = values
    self[:lce_settings] = lce.to_yaml
  end

end