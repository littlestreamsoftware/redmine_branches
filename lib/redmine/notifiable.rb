module Redmine
  class Notifiable
    # TODO: Plugin API for adding a new notification?
    def self.all
      notifications = ActiveSupport::OrderedHash.new
      notifications['issue_added'] = {}
      notifications['issue_updated'] = {:onclick => 'setCheckboxesBySelector(this.checked, ".parent-issue_updated")'}
      notifications['issue_note_added'] = {:parent => 'issue_updated'}
      notifications['issue_status_updated'] = {:parent => 'issue_updated'}
      notifications['issue_priority_updated'] = {:parent => 'issue_updated'}
      notifications['news_added'] = {}
      notifications['document_added'] = {}
      notifications['file_added'] = {}
      notifications['message_posted'] = {}
      notifications['wiki_content_added'] = {}
      notifications['wiki_content_updated'] = {}
      notifications
    end
  end
end
