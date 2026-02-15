# File Manager and Archive Defaults
{ ... }:

let
  archiveDefaults = {
    "application/zip" = "xarchiver.desktop";
    "application/x-zip-compressed" = "xarchiver.desktop";
    "application/x-7z-compressed" = "xarchiver.desktop";
    "application/x-rar" = "xarchiver.desktop";
    "application/vnd.rar" = "xarchiver.desktop";
    "application/x-tar" = "xarchiver.desktop";
    "application/x-compressed-tar" = "xarchiver.desktop";
    "application/x-gzip" = "xarchiver.desktop";
    "application/gzip" = "xarchiver.desktop";
    "application/x-bzip2" = "xarchiver.desktop";
    "application/x-xz" = "xarchiver.desktop";
    "application/x-iso9660-image" = "xarchiver.desktop";
  };
in {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = archiveDefaults // {
      "inode/directory" = "nemo.desktop";
    };
    associations.added = archiveDefaults // {
      "inode/directory" = "nemo.desktop";
    };
  };

  # Ensure existing mimeapps.list is overwritten without backup conflicts
  xdg.configFile."mimeapps.list".force = true;

  # Xarchiver defaults: extract to current directory
  home.file.".config/xarchiver/xarchiverrc".text = ''
[xarchiver]
preferred_format=0
prefer_unzip=true
confirm_deletion=true
sort_filename_content=false
advanced_isearch=true
auto_expand=true
store_output=false
icon_size=2
show_archive_comment=false
show_sidebar=true
show_location_bar=true
show_toolbar=true
preferred_custom_cmd=
preferred_temp_dir=/tmp
preferred_extract_dir=.
allow_sub_dir=0
extended_dnd=1
ensure_directory=true
overwrite=false
full_path=2
touch=false
fresh=false
update=false
store_path=false
updadd=true
freshen=false
recurse=true
solid_archive=false
remove_files=false
  '';
}
