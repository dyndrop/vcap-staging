$update_free_access = FALSE;

ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);

ini_set('session.gc_maxlifetime', 200000);

ini_set('session.cookie_lifetime', 2000000);

$conf['404_fast_paths_exclude'] = '/\/(?:styles)\//';
$conf['404_fast_paths'] = '/\.(?:txt|png|gif|jpe?g|css|js|ico|swf|flv|cgi|bat|pl|dll|exe|asp)$/i';
$conf['404_fast_html'] = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>404 Not Found</title></head><body><h1>Not Found</h1><p>The requested URL "@path" was not found on this server.</p></body></html>';

/**
 * If we are in Dyndrop, auto-feed the services data.
 */
$services = getenv('VCAP_SERVICES');
if($services) {
  $services_json = json_decode($services,true); 

  /**
   * Database config.
   */
  $mysql_config = $services_json["mysql-5.1"][0]["credentials"]; 
  $databases['default']['default'] = array( 
    'driver' => 'mysql',
    'database' => $mysql_config["name"],
    'username' => $mysql_config["user"],
    'password' => $mysql_config["password"],
    'host' => $mysql_config["hostname"],
    'port' => $mysql_config["port"],
  );

  /**
   * Redis config.
   */
  if(isset($services_json["redis-2.6"][0]["credentials"])) {
    $redis_config = $services_json["redis-2.6"][0]["credentials"]; 
    if(file_exists('sites/all/modules/redis/redis.autoload.inc')) {
      $conf['redis_client_interface'] = 'Predis';
      $conf['cache_backends'][] = 'sites/all/modules/redis/redis.autoload.inc';
      $conf['cache_default_class'] = 'Redis_Cache';
      $conf['redis_client_host'] = $redis_config["host"];
      $conf['redis_client_port'] = $redis_config["port"];
      $conf['redis_client_password'] = $redis_config["password"];
    }
  }

  /**
   * Varnish Config.
   */
  // Add Varnish as the page cache handler.
  if(file_exists('sites/all/modules/varnish/varnish.cache.inc')) {
    $conf['cache_backends'][] = 'sites/all/modules/varnish/varnish.cache.inc';
    $conf['cache_class_cache_page'] = 'VarnishCache';
    // Drupal 7 does not cache pages when we invoke hooks during bootstrap.
    // This needs to be disabled.
    $conf['page_cache_invoke_hooks'] = FALSE;
  }

  /**
   * Common caching conf.
   */
  $conf['cache'] = 1;
  $conf['page_cache_maximum_age'] = 60;

  /**
   * Tmp dir config.
   */
  $tmp_dir = getenv('TMPDIR');
  $conf['file_temporary_path'] = $tmp_dir;
}