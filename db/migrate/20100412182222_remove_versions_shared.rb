# Patch the data from the Redmine core changing how Version sharing
# works
class RemoveVersionsShared < ActiveRecord::Migration
  def self.up
    if Version.column_names.include?('shared')
      remove_column :versions, :shared
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
