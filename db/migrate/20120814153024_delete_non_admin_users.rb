class DeleteNonAdminUsers < ActiveRecord::Migration
  def up
    User.delete_all("role_id IS NULL")
  end

  def down
  end
end
