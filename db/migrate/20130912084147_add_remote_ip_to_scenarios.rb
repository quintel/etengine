class AddRemoteIpToScenarios < ActiveRecord::Migration
  def change
    add_column  :scenarios, :remote_ip, :string
  end
end
