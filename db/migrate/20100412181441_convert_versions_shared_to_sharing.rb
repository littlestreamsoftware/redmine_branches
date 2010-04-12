# Patch the data from the Redmine core changing how Version sharing works
class ConvertVersionsSharedToSharing < ActiveRecord::Migration
  def self.up
    if Version.new.respond_to?(:shared)
      Version.update_all('sharing = "none"', ['shared = ?', 'none'])
      Version.update_all('sharing = "hierarchy"', ['shared = ?', 'hierarchy'])
      Version.update_all('sharing = "system"', ['shared = ?', 'system'])
    end
  end

  def self.down
    # No-op
  end
end
