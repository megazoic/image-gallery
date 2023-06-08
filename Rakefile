# Rakefile
require 'fileutils'
require 'logger'

namespace :db do
  MIGRATIONS_DIR = 'db/migrations'
  require "sequel"
  DB = Sequel.connect(ENV.fetch("DATABASE_URL"), logger: Logger.new($stdout))
  #DB.sql_log_level = :debug
  desc "generates a migration file with a timestamp and name"
  task :generate_migration, :name do |_, args|
    args.with_defaults(name: 'migration')

    migration_template = <<~MIGRATION
      Sequel.migration do
        up do
        end

        down do
        end
      end
    MIGRATION

    file_name = "#{Time.now.strftime('%Y%m%d%H%M%S')}_#{args.name}.rb"
    FileUtils.mkdir_p(MIGRATIONS_DIR)

    File.open(File.join(MIGRATIONS_DIR, file_name), 'w') do |file|
      file.write(migration_template)
    end
  end
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel"
    Sequel.extension :migration
    db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "./db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "./db/migrations")
    end
  end
  desc "Testing fill tags"
  task :add_tags do
    tags = DB[:tags]
    particulars = ['astro', 'beach', 'fam', 'city', 'mountains']
    particulars.each do |m|
      tags.insert(name: m)
    end
  end
  desc "Reset images, tags and associations"
  task :reset_db do
    images_tags = DB[:images_tags]
    images_tags.delete
    images = DB[:images]
    images.where{id > 2}.delete
    tags = DB[:tags]
    tags.where{id > 5}.delete
  end
end
namespace :app do
  desc "find out existing env"
  task :display_env do
    puts ENV.fetch("DATABASE_URL")
  end
end
