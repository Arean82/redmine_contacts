namespace :redmine do
  namespace :contacts do

    desc <<-END_DESC
Clear tags table.

  rake redmine:contacts:clear_tags_table RAILS_ENV="production"
END_DESC

    task :clear_tags_table => :environment do
#      ActiveRecord::Migration.remove_column(:tags, :color) if RedmineCrm::Tag.column_names.include?("color")
#      ActiveRecord::Migration.remove_column(:tags, :created_at) if RedmineCrm::Tag.column_names.include?("created_at")
#      ActiveRecord::Migration.remove_column(:tags, :updated_at) if RedmineCrm::Tag.column_names.include?("updated_at")
      ActiveRecord::Migration.remove_column(:tags, :color) if Redmineup::Tag.column_names.include?("color")
      ActiveRecord::Migration.remove_column(:tags, :created_at) if Redmineup::Tag.column_names.include?("created_at")
      ActiveRecord::Migration.remove_column(:tags, :updated_at) if Redmineup::Tag.column_names.include?("updated_at")
    end
  end
end