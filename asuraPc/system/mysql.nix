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
