task :deploy => 'deploy:check' do
  sh "git push #{QriousDevops::Environments.target_environment} #{QriousDevops::Environments.target_environment}:master"
  sh "git tag #{QriousDevops::Environments.target_environment}-#{Time.now.strftime("%Y%m%d%H%M%S")}"
  sh "git fetch #{QriousDevops::Environments.target_environment}"
  Rake::Task['deploy:airbrake'].invoke
end

namespace :deploy do

  task :setup do
    fail('You must define heroku:setup task') unless Rake::Task.task_defined?('heroku:setup')
    Rake::Task['heroku:setup'].invoke
  end

  desc "Make sure we are on the right branch == environment, and branch is clean"
  task :check => :setup do
    # Check that all mentioned apps match the current git branch
    # so we can only depoy production from production branch and staging from staging branch.
    fail("You can not deploy to heroku from #{QriousDevops::Environments.current_git_branch} branch") unless QriousDevops::Environments.can_deploy?
    fail("Your working directory is not clean.") unless git_status.empty?
  end

  task :reindex do
    sh "heroku run rake db:mongoid:create_indexes --app #{QriousDevops::Environments.target_app}"
  end

  task :migrate do
    sh "heroku run rake db:migrate --app #{QriousDevops::Environments.target_app}"
  end

  task :restart do
    sh "heroku restart --app #{QriousDevops::Environments.target_app}"
  end

  task :maintenance_on do
    maintenance(QriousDevops::Environments.target_app, 'on')
  end

  task :maintenance_off do
    maintenance(QriousDevops::Environments.target_app, 'off')
  end

  task :airbrake => :environment do
    require 'airbrake_tasks'
    AirbrakeTasks.deploy(:rails_env      => QriousDevops::Environments.current_git_branch,
                         :scm_revision   => last_commit,
                         :scm_repository => '',
                         :local_username => 'kmamykin',
                         #:api_key        => ENV['API_KEY'],
                         :dry_run        => false)
  end

  def maintenance(app, action)
    sh "heroku maintenance:#{action} --app #{app}"
  end

  def git_status
    `git status --porcelain`.chomp
  end
end

def last_commit
  `git rev-parse HEAD`.chomp[0..6]
end
