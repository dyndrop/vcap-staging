require File.expand_path('../../apache_common/apache', __FILE__)

class PhpPlugin < StagingPlugin

  def resource_dir
    File.join(File.dirname(__FILE__), 'resources')
  end

  def stage_application
    Dir.chdir(destination_directory) do
      create_app_directories
      Apache.prepare(destination_directory)
      system "cp -a #{File.join(resource_dir, "conf.d", "*")} apache/php"
      copy_source_files
      # TODO: On CFv2, make a proper separate "drupal" staging plugin
      configure_source_files_for_drupal
      create_startup_script
      create_stop_script
    end
  end

  # TODO: On CFv2, make a proper separate "drupal" staging plugin
  def configure_source_files_for_drupal
    to_append = File.read(File.join(resource_dir, "drupal_settings.php"))
    if File.exists?("app/sites/default/settings.php") then
      File.open("app/sites/default/settings.php", "a") do |handle|
        handle.puts to_append
      end
    elsif File.directory?("app/sites/default") then
      File.open("app/sites/default/settings.php", "w") do |handle|
        handle.puts "<?php \n\n"
        handle.puts to_append
      end
    end
  end

  # The Apache start script runs from the root of the staged application.
  def change_directory_for_start
    "cd apache"
  end

  def start_command
    "bash ./start.sh"
  end

  def stop_command
    cmds = []
    cmds << "CHILDPIDS=$(pgrep -P ${1} -d ' ')"
    cmds << "kill -9 ${1}"
    cmds << "for CPID in ${CHILDPIDS};do"
    cmds << "  kill -9 ${CPID}"
    cmds << "done"
    cmds.join("\n")
  end

  private

  def startup_script
    generate_startup_script do
      <<-PHPEOF
env > env.log
ruby resources/generate_apache_conf $VCAP_APP_PORT $HOME $VCAP_SERVICES #{application_memory}m
/var/vcap/packages/ruby/bin/ruby resources/integrate_filesystem_service $HOME $VCAP_SERVICES
      PHPEOF
    end
  end

  def stop_script
    generate_stop_script
  end

  def apache_server_root
    File.join(destination_directory, 'apache')
  end
end
