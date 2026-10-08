# frozen_string_literal: true

# Temporary until session handles are implemented, when this column is removed.
class AddCreatorIdToScenarios < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :scenarios, :creator_id, :integer,
      comment: 'Temporary until session handles are implemented'
    )

    add_index(:scenarios, :creator_id)
  end
end
