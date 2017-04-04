class AddColumnsToIssues < ActiveRecord::Migration

  def change
    add_column :issues, :last_notification, :datetime, default: nil
  end
end