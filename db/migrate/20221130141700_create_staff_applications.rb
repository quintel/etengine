class CreateStaffApplications < ActiveRecord::Migration[7.0]
  def change
    create_table :staff_applications do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
      t.bigint :application_id, null: false

      t.index [:user_id, :name], unique: true
    end

    add_foreign_key :staff_applications, :oauth_applications, column: :application_id
  end
end
