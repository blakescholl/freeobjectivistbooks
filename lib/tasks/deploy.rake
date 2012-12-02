task :ensure_working_directory_clean do
  diff = `git status --porcelain`
  abort "There are uncommitted changes. Please commit or stash before deploying." unless diff.blank?
end

desc 'Deploy the app to Heroku'
task :deploy => %w{ensure_working_directory_clean test} do
  migrations = `git diff --name-only heroku/master -- db/migrate/`
  if migrations.present?
    puts "Found these migrations in the deployment:"
    puts migrations
  else
    puts "No migrations in the deployment; pushing code only"
  end

  sh "git push heroku master"

  if migrations.present?
    sh "heroku run rake db:migrate"
    sh "heroku restart"
  end
end
