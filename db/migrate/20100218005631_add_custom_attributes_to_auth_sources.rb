class AddCustomAttributesToAuthSources < ActiveRecord::Migration
  def self.up
    add_column :auth_sources, :custom_attributes, :text
  end

  def self.down
    remove_column :auth_sources, :custom_attributes
  end
end
