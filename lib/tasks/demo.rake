require 'faker'
require 'random_data'

ENV['REDMINE_LANG'] = 'en'

namespace :redmine do
  desc "Add a set of demo data"
  task :demo_data => [:environment, 'demo_data:users', 'demo_data:projects', 'demo_data:issues', 'demo_data:time_entries'] do
    # no op
  end
  
  namespace :demo_data do
    desc "Reloads and populates a set of data"
    task :reload => ['db:drop','db:create', 'db:migrate', 'redmine:demo_data:reset_column_info','redmine:load_default_data', 'redmine:demo_data'] do
      # no op
    end

    desc "Add up to 250 random issues"
    task :issues => :environment do
      projects = Project.find(:all)
      status = IssueStatus.find(:all)
      priorities = Enumeration.priorities
      users = User.find(:all)

      ActiveRecord::Base.observers = []
      (1..250).each do |i|
        Issue.create(
                     :tracker => Tracker.find(:first),
                     :project => projects.rand, # from faker gem
                     :subject => Faker::Company.catch_phrase,
                     :description => Random.paragraphs(3),
                     :status => status.rand,
                     :priority => priorities.rand,
                     :author => users.rand,
                     :assigned_to => users.rand
                     )
      end
      
      puts "#{Issue.count} issues total"
    end
    
    desc "Add up to 5 random users"
    task :users => :environment do

      status = [User::STATUS_ACTIVE, User::STATUS_REGISTERED, User::STATUS_LOCKED]
      
      (1..5).each do
        user = User.new(
                        :firstname => Faker::Name.first_name,
                        :lastname => Faker::Name.last_name,
                        :mail => Faker::Internet.free_email,
                        :status => status.rand
                        )
        # Protected from mass assignment
        user.login = Faker::Internet.user_name
        user.password = 'demo'
        user.password_confirmation = 'demo'
        user.save
      end
      
      puts "#{User.count} users total"
      

    end
    
    desc "Add up to 25 random projects"
    task :projects => :environment do
      (1..25).each do
        project = Project.create(
                                 :name => Faker::Company.catch_phrase[0..29],
                                 :description => Faker::Company.bs,
                                 :homepage => Faker::Internet.domain_name,
                                 :identifier => Faker::Internet.domain_word
                                 )
        project.trackers = Tracker.find(:all)
        if project.save
          # Roles
          roles = Role.find(:all)
          User.find(:all).each do |user|
            Member.create({:user => user, :project => project, :role => roles.rand})
          end

          # Modules
          Redmine::AccessControl.available_project_modules.each do |module_name|
            EnabledModule.create(:name => module_name, :project => project)
          end
        end
      end
      
      puts "#{Project.count} projects total"
      
    end

    desc "Add up to 250 random time entries"
    task :time_entries => :environment do
      users = User.find(:all)
      projects = Project.find(:all)
      issues = Issue.find(:all)
      activities = Enumeration.activities
      
      (1..250).each do
        issue = issues.rand
        TimeEntry.create(
                         :project => issue.project,
                         :user => users.rand,
                         :issue => issue,
                         :hours => (1..20).to_a.rand,
                         :comments => Faker::Company.bs,
                         :activity => activities.rand,
                         :spent_on => Random.date
                         )
      end
      
      puts "#{TimeEntry.count} time entries total"
      
    end

    # Resets all subclass column information from migrations
    task :reset_column_info do
      ActiveRecord::Base.send(:subclasses).each {|klass| klass.reset_column_information }
    end
  end
end
