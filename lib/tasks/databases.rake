require 'open3'

class MongoInstance
  def self.development
    new(QriousDevops::Environments.development_mongodb_uri)
  end

  def self.staging
    new(QriousDevops::Environments.mongo_url(:staging))
  end

  def self.production
    new(QriousDevops::Environments.mongo_url(:production))
  end

  def initialize(uri)
    @uri = URI.parse(uri)
    @host = @uri.host || "localhost"
    @port = @uri.port || 27017
    @db = @uri.path.delete('/')
    @user = @uri.user
    @password = @uri.password
  end

  def dump(dir)
    puts "-----> Downloading #{@uri} to #{dir}"
    FileUtils.mkdir_p(dir)
    exec "mongodump -v #{connection_params} --out #{dir}"
  end

  def restore(dir)
    exec "mongorestore -v --drop #{connection_params} #{dir}"
  end

  def backup
    dump QriousDevops::Environments.new_backup_dir
  end

  def restore_latest
    restore QriousDevops::Environments.latest_backup_dir
  end

  private
  def connection_params
    connection = "--host #{@host}:#{@port}"
    connection += " --db #{@db}" if @db
    connection += " -u #{@user}" if @user
    connection += " -p#{@password}" if @password  # NOTE: no space b/w -p and password, see http://stackoverflow.com/questions/7521163/what-does-too-many-positional-options-mean-when-doing-a-mongoexport
    connection
  end

  def exec(command)
    puts "-----> Running #{command}"
    system(command) || fail("Could not complete #{command}")
  end
end

class RedisInstance
  def self.development
    new(QriousDevops::Environments.development_redis_uri)
  end

  def self.staging
    new(QriousDevops::Environments.redis_url(:staging))
  end

  def self.production
    new(QriousDevops::Environments.redis_url(:production))
  end

  attr_reader :host, :port, :password

  def initialize(uri)
    @uri = URI.parse(uri)
    @host = @uri.host
    @port = @uri.port
    @db = @uri.path.delete('/')
    @user = @uri.user
    @password = @uri.password
  end

  def start
    sh "redis-server config/redis.conf"
  end

  def stop
    sh "redis-cli shutdown"
  end

  def make_slave_of(target)
    stdin, stdout, stderr = Open3.popen3("redis-cli #{connections_params}")
    stdin.puts("CONFIG SET MASTERAUTH #{target.password}")
    stdin.puts("SLAVEOF #{target.host} #{target.port}")
    puts stdout.gets

    puts "Waiting 60 sec..."
    sleep 60
    stdin.puts("SLAVEOF NO ONE")
    puts stdout.gets
  end

  private

  def connections_params
    connection = ""
    connection += "-h #{@host} " if @host
    connection += "-p #{@port} " if @port
    connection += "-a #{@password}" if @password
    connection
  end

end

namespace :db do
  task :download => ['db:production_backup', 'db:local_restore', 'redis:local_restore']

  task :production_backup do
    MongoInstance.production.backup
  end

  task :local_restore do
    MongoInstance.development.restore_latest
  end

  task :staging_restore do
    MongoInstance.staging.restore_latest
  end
end

namespace :redis do
  desc "Start redis server in daemon mode"
  task :start do
    RedisInstance.development.start
  end

  desc "Stop redis server"
  task :stop do
    RedisInstance.development.stop
  end

  task :local_restore do
    RedisInstance.development.make_slave_of(RedisInstance.production)
  end
  task :staging_restore do
    RedisInstance.staging.make_slave_of(RedisInstance.production)
  end
end
