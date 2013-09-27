module QriousDevops
  class Environments

    def self.development_mongodb_uri
      "mongodb://localhost:27017/qrious_development"
    end

    def self.development_redis_uri
      "redis://redis@localhost/"
    end

    def self.new_backup_dir
      "db/backups/production/#{Time.now.strftime("%Y%m%d_%H%M%S")}"
    end

    def self.latest_backup_dir
      Dir["db/backups/production/*/*"].sort.last
    end

    def self.mongo_url(env)
      `heroku config --app #{heroku_app(env)}`
      `heroku config --app #{heroku_app(env)}`.scan(/^MONGODB_URL\s*:\s*(.+)$/).flatten.first
    end

    def self.redis_url(env)
      `heroku config --app #{heroku_app(env)}`.scan(/^REDISTOGO_URL\s*:\s*(.+)$/).flatten.first
    end

    def self.can_deploy?
      environments.keys.include?(target_environment)
    end

    def self.target_environment
      current_git_branch.to_sym
    end

    def self.target_app
      heroku_app(target_environment)
    end

    def self.heroku_app(env)
      environments[env.to_sym][:heroku_app]
    end

    def self.environments
      @env
    end

    def self.environments=(hash)
      @env = hash
    end

    def self.current_git_branch
      @current_git_branch ||= `git symbolic-ref HEAD 2>/dev/null`.chomp.gsub("refs/heads/", "")
    end

  end
end
