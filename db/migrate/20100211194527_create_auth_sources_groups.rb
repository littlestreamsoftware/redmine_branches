class CreateAuthSourcesGroups < ActiveRecord::Migration
  def self.up
    create_table :auth_sources_groups, :id => false do |t|
      t.column :auth_source_id, :integer, :null => false
      t.column :group_id, :integer, :null => false
    end
    add_index :auth_sources_groups, [:auth_source_id, :group_id], :unique => true, :name => :auth_sources_groups_id
  end

  def self.down
    drop_table :auth_sources_groups
  end
end
