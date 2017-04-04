class AddColumnToIssue < ActiveRecord::Migration

  def change
    add_column :issues, :reminder_date, :date, default: nil
    add_column :issues, :reminder_option, :string, default: nil
  end
end
