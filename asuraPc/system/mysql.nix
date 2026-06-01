# Local MySQL 8.4 server and desktop tooling.
{ pkgs, ... }:

{
  services.mysql = {
    enable = true;
    package = pkgs.mysql84;
    dataDir = "/var/lib/mysql";

    settings = {
      client = {
        socket = "/run/mysqld/mysqld.sock";
        port = 3306;
      };
      mysqld = {
        bind-address = "127.0.0.1";
        socket = "/run/mysqld/mysqld.sock";
        mysqlx = 0;

        # Low-memory optimizations for local development
        performance_schema = 0;
        innodb_buffer_pool_size = "16M";
        innodb_log_buffer_size = "2M";
        max_connections = 10;
        key_buffer_size = "8M";
        thread_cache_size = 0;
        host_cache_size = 0;
      };
    };

    ensureDatabases = [ "asura_dev" ];
    ensureUsers = [
      {
        name = "asura";
        ensurePermissions = {
          "asura_dev.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  environment.sessionVariables = {
    MYSQL_HOST = "127.0.0.1";
    MYSQL_TCP_PORT = "3306";
    MYSQL_UNIX_PORT = "/run/mysqld/mysqld.sock";
    MYSQL_HOME = "/etc";
  };
}
