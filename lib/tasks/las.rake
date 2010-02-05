namespace :las do
  desc 'Data patch for issue #3591'
  task :patch_for_3591 => :environment do
    puts User.update_all("mail_notification = 'only_my_events'", "mail_notification = 'my_events'")
  end
end
