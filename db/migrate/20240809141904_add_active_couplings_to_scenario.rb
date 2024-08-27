class AddActiveCouplingsToScenario < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :active_couplings, :text, size: :medium
  end
end
