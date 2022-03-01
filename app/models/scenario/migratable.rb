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
        '(protected = :protected OR updated_at >= :updated_at) AND ' \
        'COALESCE(source, "") != :mechanical_turk_source AND ' \
        'user_values IS NOT NULL AND user_values != :empty_user_values',
        protected: true,
        updated_at: since,
        mechanical_turk_source: 'Mechanical Turk',
        empty_user_values: ActiveSupport::HashWithIndifferentAccess.new.to_yaml
      )
    end
  end
end
