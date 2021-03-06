require 'spec_helper'

describe "A Rails 3 application being staged" do
  it "FIXME doesn't load the schema when there are no migrations"

  before do
    app_fixture :rails3_nodb
  end

  it "is packaged with a startup script" do
    stage rails_staging_env do |staged_dir|
      executable = '%VCAP_LOCAL_RUNTIME%'
      start_script = File.join(staged_dir, 'startup')
      start_script.should be_executable_file
      script_body = File.read(start_script)

      script_body.should == <<-EXPECTED
#!/bin/bash
export DISABLE_AUTO_CONFIG="mysql:postgresql"
export GEM_HOME="$PWD/app/rubygems/ruby/1.8"
export GEM_PATH="$PWD/app/rubygems/ruby/1.8"
export PATH="$PWD/app/rubygems/ruby/1.8/bin:$PATH"
export RAILS_ENV="${RAILS_ENV:-production}"
export RUBYOPT="-I$PWD/ruby -I$PWD/app/rubygems/ruby/1.8/gems/cf-autoconfig-#{AUTO_CONFIG_GEM_VERSION}/lib -rcfautoconfig -rstdsync"
export TMPDIR="$PWD/tmp"
mkdir ruby
echo "\\$stdout.sync = true" >> ./ruby/stdsync.rb
if [ -f "$PWD/app/config/database.yml" ] ; then
  cd app && #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rake db:migrate --trace >>../logs/migration.log 2>> ../logs/migration.log && cd ..;
fi
if [ -n "$VCAP_CONSOLE_PORT" ]; then
  cd app
  #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} cf-rails-console/rails_console.rb >>../logs/console.log 2>> ../logs/console.log &
  CONSOLE_STARTED=$!
  echo "$CONSOLE_STARTED" >> ../console.pid
  cd ..
fi
DROPLET_BASE_DIR=$PWD
cd app
#{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rails server $@ > $DROPLET_BASE_DIR/logs/stdout.log 2> $DROPLET_BASE_DIR/logs/stderr.log &
STARTED=$!
echo "$STARTED" >> $DROPLET_BASE_DIR/run.pid
wait $STARTED
      EXPECTED
    end
  end

  it "installs autoconfig gem" do
     stage rails_staging_env do |staged_dir|
       gemfile = File.join(staged_dir,'app','Gemfile')
       gemfile_body = File.read(gemfile)
       gemfile_body.should == <<-EXPECTED
source 'http://rubygems.org'

gem 'rails', '3.0.4'

gem "cf-autoconfig"
     EXPECTED
    end
  end

  describe "which bundles 'thin'" do
    before do
      app_fixture :rails3_no_assets
    end

    it "is started with `rails server thin`" do
      stage rails_staging_env do |staged_dir|
        executable = '%VCAP_LOCAL_RUNTIME%'
        start_script = File.join(staged_dir, 'startup')
        script_body = File.read(start_script)

        script_body.should == <<-EXPECTED
#!/bin/bash
export DISABLE_AUTO_CONFIG="mysql:postgresql"
export GEM_HOME="$PWD/app/rubygems/ruby/1.8"
export GEM_PATH="$PWD/app/rubygems/ruby/1.8"
export PATH="$PWD/app/rubygems/ruby/1.8/bin:$PATH"
export RAILS_ENV="${RAILS_ENV:-production}"
export RUBYOPT="-I$PWD/ruby -I$PWD/app/rubygems/ruby/1.8/gems/cf-autoconfig-#{AUTO_CONFIG_GEM_VERSION}/lib -rcfautoconfig -rstdsync"
export TMPDIR="$PWD/tmp"
mkdir ruby
echo "\\$stdout.sync = true" >> ./ruby/stdsync.rb
if [ -f "$PWD/app/config/database.yml" ] ; then
  cd app && #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rake db:migrate --trace >>../logs/migration.log 2>> ../logs/migration.log && cd ..;
fi
if [ -n "$VCAP_CONSOLE_PORT" ]; then
  cd app
  #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} cf-rails-console/rails_console.rb >>../logs/console.log 2>> ../logs/console.log &
  CONSOLE_STARTED=$!
  echo "$CONSOLE_STARTED" >> ../console.pid
  cd ..
fi
DROPLET_BASE_DIR=$PWD
cd app
#{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rails server thin $@ > $DROPLET_BASE_DIR/logs/stdout.log 2> $DROPLET_BASE_DIR/logs/stderr.log &
STARTED=$!
echo "$STARTED" >> $DROPLET_BASE_DIR/run.pid
wait $STARTED
        EXPECTED
      end
    end
  end

  it "is packaged with the appropriate Rails plugin" do
      stage rails_staging_env do |staged_dir|
        plugin_dir = staged_dir.join('app', 'vendor', 'plugins')
        plugin_dir.join('configure_assets').should be_directory
        plugin_dir.join('configure_assets', 'init.rb').should be_readable
      end
    end

  it "receives the rails console" do
    stage rails_staging_env do |staged_dir|
      plugin_dir = staged_dir.join('app', 'cf-rails-console')
      plugin_dir.should be_directory
      access_file = staged_dir.join('app', 'cf-rails-console','.consoleaccess')
      config = YAML.load_file(access_file)
      config['username'].should_not be_nil
      config['password'].should_not be_nil
    end
  end

  describe "which enables DB migrations using the db migrate property" do
    before do
      app_fixture :rails3_no_assets
    end

    it "generates a start script that includes db:migrate" do
      stage rails_staging_env do |staged_dir|
        executable = '%VCAP_LOCAL_RUNTIME%'
        start_script = File.join(staged_dir, 'startup')
        script_body = File.read(start_script)
        script_body.should == <<-EXPECTED
#!/bin/bash
export DISABLE_AUTO_CONFIG="mysql:postgresql"
export GEM_HOME="$PWD/app/rubygems/ruby/1.8"
export GEM_PATH="$PWD/app/rubygems/ruby/1.8"
export PATH="$PWD/app/rubygems/ruby/1.8/bin:$PATH"
export RAILS_ENV="${RAILS_ENV:-production}"
export RUBYOPT="-I$PWD/ruby -I$PWD/app/rubygems/ruby/1.8/gems/cf-autoconfig-#{AUTO_CONFIG_GEM_VERSION}/lib -rcfautoconfig -rstdsync"
export TMPDIR="$PWD/tmp"
mkdir ruby
echo "\\$stdout.sync = true" >> ./ruby/stdsync.rb
if [ -f "$PWD/app/config/database.yml" ] ; then
  cd app && #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rake db:migrate --trace >>../logs/migration.log 2>> ../logs/migration.log && cd ..;
fi
if [ -n "$VCAP_CONSOLE_PORT" ]; then
  cd app
  #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} cf-rails-console/rails_console.rb >>../logs/console.log 2>> ../logs/console.log &
  CONSOLE_STARTED=$!
  echo "$CONSOLE_STARTED" >> ../console.pid
  cd ..
fi
DROPLET_BASE_DIR=$PWD
cd app
#{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rails server thin $@ > $DROPLET_BASE_DIR/logs/stdout.log 2> $DROPLET_BASE_DIR/logs/stderr.log &
STARTED=$!
echo "$STARTED" >> $DROPLET_BASE_DIR/run.pid
wait $STARTED
        EXPECTED
      end
    end
  end

  describe "which disables DB migrations" do
    before do
      app_fixture :rails3_db_migrations_disabled
    end

    it "generates a start script that does not include db:migrate" do
      stage rails_staging_env do |staged_dir|
        executable = '%VCAP_LOCAL_RUNTIME%'
        start_script = File.join(staged_dir, 'startup')
        script_body = File.read(start_script)
        script_body.should == <<-EXPECTED
#!/bin/bash
export DISABLE_AUTO_CONFIG="mysql:postgresql"
export GEM_HOME="$PWD/app/rubygems/ruby/1.8"
export GEM_PATH="$PWD/app/rubygems/ruby/1.8"
export PATH="$PWD/app/rubygems/ruby/1.8/bin:$PATH"
export RAILS_ENV="${RAILS_ENV:-production}"
export RUBYOPT="-I$PWD/ruby -rstdsync"
export TMPDIR="$PWD/tmp"
mkdir ruby
echo "\\$stdout.sync = true" >> ./ruby/stdsync.rb
if [ -n "$VCAP_CONSOLE_PORT" ]; then
  cd app
  #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} cf-rails-console/rails_console.rb >>../logs/console.log 2>> ../logs/console.log &
  CONSOLE_STARTED=$!
  echo "$CONSOLE_STARTED" >> ../console.pid
  cd ..
fi
DROPLET_BASE_DIR=$PWD
cd app
#{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rails server thin $@ > $DROPLET_BASE_DIR/logs/stdout.log 2> $DROPLET_BASE_DIR/logs/stderr.log &
STARTED=$!
echo "$STARTED" >> $DROPLET_BASE_DIR/run.pid
wait $STARTED
        EXPECTED
      end
    end
  end
  describe "which enables DB migrations through absence of dbmigrate property" do
    before do
      app_fixture :rails3_nodb
    end

    it "generates a start script that includes db:migrate" do
      stage rails_staging_env do |staged_dir|
        executable = '%VCAP_LOCAL_RUNTIME%'
        start_script = File.join(staged_dir, 'startup')
        start_script.should be_executable_file
        script_body = File.read(start_script)

        script_body.should == <<-EXPECTED
#!/bin/bash
export DISABLE_AUTO_CONFIG="mysql:postgresql"
export GEM_HOME="$PWD/app/rubygems/ruby/1.8"
export GEM_PATH="$PWD/app/rubygems/ruby/1.8"
export PATH="$PWD/app/rubygems/ruby/1.8/bin:$PATH"
export RAILS_ENV="${RAILS_ENV:-production}"
export RUBYOPT="-I$PWD/ruby -I$PWD/app/rubygems/ruby/1.8/gems/cf-autoconfig-#{AUTO_CONFIG_GEM_VERSION}/lib -rcfautoconfig -rstdsync"
export TMPDIR="$PWD/tmp"
mkdir ruby
echo "\\$stdout.sync = true" >> ./ruby/stdsync.rb
if [ -f "$PWD/app/config/database.yml" ] ; then
  cd app && #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rake db:migrate --trace >>../logs/migration.log 2>> ../logs/migration.log && cd ..;
fi
if [ -n "$VCAP_CONSOLE_PORT" ]; then
  cd app
  #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} cf-rails-console/rails_console.rb >>../logs/console.log 2>> ../logs/console.log &
  CONSOLE_STARTED=$!
  echo "$CONSOLE_STARTED" >> ../console.pid
  cd ..
fi
DROPLET_BASE_DIR=$PWD
cd app
#{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rails server $@ > $DROPLET_BASE_DIR/logs/stdout.log 2> $DROPLET_BASE_DIR/logs/stderr.log &
STARTED=$!
echo "$STARTED" >> $DROPLET_BASE_DIR/run.pid
wait $STARTED
        EXPECTED
      end
    end
  end

  describe "which has a database.yml" do
    before do
      app_fixture :rails3_no_assets
    end

    it "is auto-reconfigured with DB settings" do
      stage(rails_staging_env([{:label=>"postgresql-9.0",
        :credentials=>{:hostname=>"myhost", :user=>"testuser", :port=>345, :password=>"test", :name=>"mydb"}}])) do |staged_dir|
        env = staged_dir.join('app', 'config', 'database.yml')
        db_settings = YAML.load_file(env)
        db_settings['production'].should == {'adapter' => 'postgresql', 'encoding' => 'utf8', 'pool' => 5,
          'reconnect' => false, 'host'=>"myhost", 'username'=>"testuser", 'port'=>345, 'password'=>"test", 'database'=>"mydb"}
        # Verify other sections remain untouched
        db_settings['test'].should == {'adapter' => 'sqlite3', 'database' => 'db/test.sqlite3', 'pool' => 5, 'timeout' => 5000}
        db_settings['development'].should == {'adapter' => 'sqlite3', 'database' => 'db/development.sqlite3', 'pool' => 5, 'timeout' => 5000}
      end
    end

    it "is auto-reconfigured with DB settings when there are 2 services, one named for env" do
      stage(rails_staging_env([{:label=>"postgresql-9.0",
        :name=> "myservice", :credentials=>{:hostname=>"thehost", :user=>"auser", :port=>34567, :password=>"testa", :name=>"mydb23"}},
        {:label=>"postgresql-9.0", :name=>"mydb-production",
        :credentials=>{:hostname=>"myhost", :user=>"testuser", :port=>345, :password=>"test", :name=>"mydb"}}])) do |staged_dir|
        env = staged_dir.join('app', 'config', 'database.yml')
        db_settings = YAML.load_file(env)
        db_settings['production'].should == {'adapter' => 'postgresql', 'encoding' => 'utf8', 'pool' => 5,
          'reconnect' => false, 'host'=>"myhost", 'username'=>"testuser", 'port'=>345, 'password'=>"test", 'database'=>"mydb"}
      end
    end

    it "is auto-reconfigured with DB settings when there are 2 services, one named with 'prod'" do
      stage(rails_staging_env([{:label=>"postgresql-9.0",
        :name=> "myservice", :credentials=>{:hostname=>"thehost", :user=>"auser", :port=>34567, :password=>"testa", :name=>"mydb23"}},
        {:label=>"postgresql-9.0", :name=>"mydb-prod",
        :credentials=>{:hostname=>"myhost", :user=>"testuser", :port=>345, :password=>"test", :name=>"mydb"}}])) do |staged_dir|
        env = staged_dir.join('app', 'config', 'database.yml')
        db_settings = YAML.load_file(env)
        db_settings['production'].should == {'adapter' => 'postgresql', 'encoding' => 'utf8', 'pool' => 5,
          'reconnect' => false, 'host'=>"myhost", 'username'=>"testuser", 'port'=>345, 'password'=>"test", 'database'=>"mydb"}
      end
    end

    it "is not auto-reconfigured when there are 2 services not named prod" do
      lambda {stage(rails_staging_env([{:label=>"postgresql-9.0",
        :name=> "myservice", :credentials=>{:hostname=>"thehost", :user=>"auser", :port=>34567, :password=>"testa", :name=>"mydb23"}},
        {:label=>"postgresql-9.0", :name=>"mydbservice",
        :credentials=>{:hostname=>"myhost", :user=>"testuser", :port=>345, :password=>"test", :name=>"mydb"}}]))}.should raise_error RuntimeError
    end

    it "is not auto-reconfigured when DB binding is missing credentials" do
      lambda {stage(rails_staging_env([{:label=>"postgresql-9.0",
        :name=> "myservice"}]))}.should raise_error RuntimeError
    end
  end

  describe "which has no database.yml" do
     before do
      app_fixture :rails3_nodb
     end

     it 'is auto-reconfigured with DB settings when service present' do
       stage(rails_staging_env([{:label=>"postgresql-9.0",
        :credentials=>{:hostname=>"myhost", :user=>"testuser", :port=>345, :password=>"test", :name=>"mydb"}}])) do |staged_dir|
        env = staged_dir.join('app', 'config', 'database.yml')
        db_settings = YAML.load_file(env)
        db_settings['production'].should == {'adapter' => 'postgresql', 'encoding' => 'utf8', 'pool' => 5,
          'reconnect' => false, 'host'=>"myhost", 'username'=>"testuser", 'port'=>345, 'password'=>"test", 'database'=>"mydb"}
       end
    end

    it 'is does not fail staging during autoconfig with no services' do
       stage(rails_staging_env) do |staged_dir|
         executable = '%VCAP_LOCAL_RUNTIME%'
         start_script = File.join(staged_dir, 'startup')
         start_script.should be_executable_file
         script_body = File.read(start_script)

         script_body.should == <<-EXPECTED
#!/bin/bash
export DISABLE_AUTO_CONFIG="mysql:postgresql"
export GEM_HOME="$PWD/app/rubygems/ruby/1.8"
export GEM_PATH="$PWD/app/rubygems/ruby/1.8"
export PATH="$PWD/app/rubygems/ruby/1.8/bin:$PATH"
export RAILS_ENV="${RAILS_ENV:-production}"
export RUBYOPT="-I$PWD/ruby -I$PWD/app/rubygems/ruby/1.8/gems/cf-autoconfig-#{AUTO_CONFIG_GEM_VERSION}/lib -rcfautoconfig -rstdsync"
export TMPDIR="$PWD/tmp"
mkdir ruby
echo "\\$stdout.sync = true" >> ./ruby/stdsync.rb
if [ -f "$PWD/app/config/database.yml" ] ; then
  cd app && #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rake db:migrate --trace >>../logs/migration.log 2>> ../logs/migration.log && cd ..;
fi
if [ -n "$VCAP_CONSOLE_PORT" ]; then
  cd app
  #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} cf-rails-console/rails_console.rb >>../logs/console.log 2>> ../logs/console.log &
  CONSOLE_STARTED=$!
  echo "$CONSOLE_STARTED" >> ../console.pid
  cd ..
fi
DROPLET_BASE_DIR=$PWD
cd app
#{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rails server $@ > $DROPLET_BASE_DIR/logs/stdout.log 2> $DROPLET_BASE_DIR/logs/stderr.log &
STARTED=$!
echo "$STARTED" >> $DROPLET_BASE_DIR/run.pid
wait $STARTED
         EXPECTED
      end
    end
  end

  describe "which disables auto-reconfig" do
    before do
      app_fixture :rails3_db_migrations_disabled
    end

    it "generates a start script that does not include auto-reconfig" do
      stage rails_staging_env do |staged_dir|
        executable = '%VCAP_LOCAL_RUNTIME%'
        start_script = File.join(staged_dir, 'startup')
        script_body = File.read(start_script)
        script_body.should == <<-EXPECTED
#!/bin/bash
export DISABLE_AUTO_CONFIG="mysql:postgresql"
export GEM_HOME="$PWD/app/rubygems/ruby/1.8"
export GEM_PATH="$PWD/app/rubygems/ruby/1.8"
export PATH="$PWD/app/rubygems/ruby/1.8/bin:$PATH"
export RAILS_ENV="${RAILS_ENV:-production}"
export RUBYOPT="-I$PWD/ruby -rstdsync"
export TMPDIR="$PWD/tmp"
mkdir ruby
echo "\\$stdout.sync = true" >> ./ruby/stdsync.rb
if [ -n "$VCAP_CONSOLE_PORT" ]; then
  cd app
  #{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} cf-rails-console/rails_console.rb >>../logs/console.log 2>> ../logs/console.log &
  CONSOLE_STARTED=$!
  echo "$CONSOLE_STARTED" >> ../console.pid
  cd ..
fi
DROPLET_BASE_DIR=$PWD
cd app
#{executable} ./rubygems/ruby/1.8/bin/bundle exec #{executable} ./rubygems/ruby/1.8/bin/rails server thin $@ > $DROPLET_BASE_DIR/logs/stdout.log 2> $DROPLET_BASE_DIR/logs/stderr.log &
STARTED=$!
echo "$STARTED" >> $DROPLET_BASE_DIR/run.pid
wait $STARTED
        EXPECTED
      end
    end
  end

  describe "with development and test groups" do
    before do
      app_fixture :rails3_no_assets
    end

    it "does not install gems from test and development groups" do
      stage rails_staging_env do |staged_dir|
        gem_dir = File.join(staged_dir,"app", "rubygems", "ruby", "1.8","gems")
        installed_gems = Dir.entries(gem_dir)
        installed_gems.should_not include "rspec-2.11.0" # test
        installed_gems.should_not include "rubyzip-0.9.9" # development
      end
    end

    it "installs development gems if RAILS_ENV=development and does not install test gems" do
      stage rails_staging_env.merge({:environment => ["RAILS_ENV=development"]}) do |staged_dir|
        gem_dir = File.join(staged_dir,"app", "rubygems", "ruby", "1.8","gems")
        installed_gems = Dir.entries(gem_dir)
        installed_gems.should_not include "rspec-2.11.0" # test
        installed_gems.should include "rubyzip-0.9.9" # development
      end
    end
  end
end

describe "Rails3Plugin" do
  before :each do
    @working_dir = Dir.mktmpdir
    @plugin = StagingPlugin.load_plugin_for(rails_staging_env[:framework_info][:name])
  end

  after :each do
    FileUtils.rm_rf(@working_dir) if @working_dir
  end

  it "adds live compilation in assets plugin" do
    expected_assets_config = <<BODY
Rails.application.config.serve_static_assets = true
Rails.application.config.assets.compile = true
BODY
    stager = @plugin.new(@working_dir, @working_dir, rails_staging_env)
    stager.create_asset_plugin({:live_compilation => true})
    config = File.read(File.join(@working_dir, "app", "vendor", "plugins", "configure_assets", "init.rb"))
    config.should == expected_assets_config
  end
end

def rails_staging_env(services=[])
  {
    :runtime_info => {
      :name => "ruby18",
      :version => "1.8.7",
      :description => "Ruby 1.8.7",
      :executable => "/usr/bin/ruby",
      :environment => {"bundle_gemfile" => nil}
    },
    :framework_info => {
       :name => "rails3",
       :runtimes => [{"ruby18" => {"default" => true}}, {"ruby19" => {"default" => false}}],
       :detection => [{"config/application.rb" => true}, {"config/environment.rb" => true}]
    },
    :services => services
  }
end
