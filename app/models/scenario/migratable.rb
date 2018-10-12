class Scenario < ApplicationRecord
  # ActiveRecord scopes used when migrating scenarios with new user values.
  module Migratable
    # Public: Scenarios which should receive new user values when the ETSource
    # data requires changes to existing scenarios.
    #
    # See migratable_since
    #
    # Returns an ActiveRecord::Relation
    def migratable
      migratable_since(1.month.ago.to_date)
    end

    # Public: Scenarios which should receive new user values when the ETSource
    # data requires changes to existing scenarios.
    #
    # All protected scenarios are included, and any unprotected scenarios updated
    # on or after the `since` date or time. Test scenarios and Mechanical Turk
    # scenarios are excluded.
    #
    # Returns an ActiveRecord::Relation
    def migratable_since(since)
      Scenario.where(
        '(protected = ? OR updated_at >= ?) AND ' \
        'COALESCE(source, "") != ? AND ' \
        'COALESCE(title, "") != ? AND ' \
        'user_values IS NOT NULL AND user_values != ?',
        true, since, 'Mechanical Turk', 'test',
        ActiveSupport::HashWithIndifferentAccess.new.to_yaml
      )
    end
  end
end
