# Load, copy, reset and save
#
module Scenario::Persistable
  extend ActiveSupport::Concern

  # Reset all values that can be changed by a user and influences GQL
  # to the default/empty values.
  #
  # @tested 2010-12-06 seb
  #
  def reset!
    self.user_values = {}

    # @inputs have to be nil, not an empty hash. otherwise
    # the memoized inputs will not pick up the changes.
    @inputs = nil
  end

  # Stores the current settings into the attributes. For when we want to save
  # the scenario in the db.
  #
  # @untested 2010-12-06 seb
  #
  def copy_scenario_state(preset)
    source_user_values = preset.user_values.clone
    source_bal_values  = (vals = preset.try(:balanced_values)) && vals.clone
    other_scaler       = preset.scaler

    # If this scenario has a custom scaling (different from that in the source
    # preset), we have to re-scale the value of each input so that it makes
    # sense when used in the newly-sized area.
    if self.scaler || (self.descale && other_scaler)
      source_user_values = rescale_inputs(
        source_user_values, other_scaler, self.scaler)

      source_bal_values = rescale_inputs(
        source_bal_values || {}, other_scaler, self.scaler)
    end

    self.user_values.reverse_merge!(source_user_values)

    if source_bal_values
      self.balanced_values.reverse_merge!(source_bal_values)
    end

    # Set the same scaler as the source scenario, except when the user has
    # specified a custom scaling.
    if other_scaler && ! self.scaler && ! self.descale
      self.scaler = ScenarioScaling.new(
        other_scaler.attributes.except('id', 'scenario_id'))
    end

    self.heat_network_order = cloned_user_sortable(preset, :heat_network_order)

    cloned_attachments(preset) do |cloned_attachment|
      self.attachments << cloned_attachment
    end

    self.end_year  = preset.end_year
    self.area_code = preset.area_code
  end

  #######
  private
  #######

  # Internal: Given a collection of inputs, scales the values so that they fit
  # in the new scenario.
  #
  # Returns a hash.
  def rescale_inputs(collection, source_scaler, dest_scaler)
    collection.each_with_object({}) do |(key, value), data|
      input = Input.get(key.to_sym)

      # Old scenarios may use inputs which no longer exist; skip them.
      next unless input

      if ScenarioScaling.scale_input?(input)
        data[key] = rescale_input(value, source_scaler, dest_scaler)
      else
        data[key] = value
      end
    end
  end

  # Internal: See `rescale_inputs`.
  #
  # Returns a numeric.
  def rescale_input(value, source_scaler, dest_scaler)
    if source_scaler
      descaled = source_scaler.descale(value)
      dest_scaler ? dest_scaler.scale(descaled) : descaled
    elsif dest_scaler
      dest_scaler.scale(value)
    end
  end

  # Internal: If the source preset has one or more user sortables, creates a clone to be used by the
  # new scenario.
  #
  # Returns a UserSortable or nil.
  def cloned_user_sortable(preset, attribute)
    if (order = preset.try(attribute))
      order.class.new(order.attributes.except('id', 'scenario_id'))
    end
  end

  # Internal: Attaches the imported electricity price curve from the preset
  # scenario to new scenario attachments.
  def cloned_attachments(preset)
    attachments = preset.attachments

    return if attachments.blank?

    attachments.each do |attachment|
      cloned_attachment = ScenarioAttachment.new(
        attachment.attributes.except('id', 'scenario_id')
      )

      cloned_attachment.file.attach(attachment.file.blob)

      yield cloned_attachment
    end
  end
end
