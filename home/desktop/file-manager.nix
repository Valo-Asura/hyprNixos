# File Manager, archive, and viewer defaults
{ lib, ... }:

let
  ark = "org.kde.ark.desktop";
  loupe = "org.gnome.Loupe.desktop";
  okular = "org.kde.okular.desktop";

  archiveDefaults = {
    "application/zip" = ark;
    "application/x-zip-compressed" = ark;
    "application/x-7z-compressed" = ark;
    "application/x-rar" = ark;
    "application/vnd.rar" = ark;
    "application/x-tar" = ark;
    "application/x-compressed-tar" = ark;
    "application/x-bzip-compressed-tar" = ark;
    "application/x-bzip2-compressed-tar" = ark;
    "application/x-xz-compressed-tar" = ark;
    "application/x-gzip" = ark;
    "application/gzip" = ark;
    "application/x-bzip2" = ark;
    "application/x-xz" = ark;
    "application/zstd" = ark;
    "application/x-lz4" = ark;
    "application/x-iso9660-image" = ark;
  };

  viewerDefaults = {
    "image/jpeg" = loupe;
    "image/jpg" = loupe;
    "image/png" = loupe;
    "image/gif" = loupe;
    "image/webp" = loupe;
    "image/avif" = loupe;
    "image/svg+xml" = loupe;

    "application/pdf" = lib.mkForce okular;
    "application/epub+zip" = okular;
    "application/postscript" = okular;
    "image/vnd.djvu" = okular;

    "audio/mpeg" = "mpv.desktop";
    "audio/flac" = "mpv.desktop";
    "audio/ogg" = "mpv.desktop";
    "audio/wav" = "mpv.desktop";
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
  };

  desktopDefaults =
    archiveDefaults
    // viewerDefaults
    // {
      "inode/directory" = "thunar.desktop";
    };
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = desktopDefaults;
    associations.added = desktopDefaults;
  };

  # Ensure existing mimeapps.list is overwritten without backup conflicts
  xdg.configFile."mimeapps.list".force = true;

  # Keep Xarchiver usable as a fallback even though Ark is the default archive app.
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
