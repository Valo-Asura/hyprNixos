# File Manager, archive, and viewer defaults
{ lib, ... }:

let
  ark = "org.kde.ark.desktop";
  nautilus = "org.gnome.Nautilus.desktop";
  loupe = "org.gnome.Loupe.desktop";
  okular = "org.kde.okular.desktop";
  pcmanfmQtSettings = ''
    [Behavior]
    AutoSelectionDelay=600
    BookmarkOpenMethod=current_tab
    ConfirmDelete=true
    ConfirmTrash=false
    NoUsbTrash=false
    RecentFilesNumber=0
    SingleClick=false
    SingleWindowMode=false
    UseTrash=true

    [Desktop]
    BgColor=#191724
    FgColor=#e0def4
    HideItems=false
    ShadowColor=#000000
    ShowHidden=true
    SortColumn=name
    SortFolderFirst=true
    SortHiddenLast=false
    SortOrder=ascending

    [FolderView]
    BigIconSize=48
    Mode=icon
    ScrollPerPixel=true
    ShadowHidden=true
    ShowFilter=false
    ShowFullNames=true
    ShowHidden=true
    SidePaneIconSize=24
    SmallIconSize=24
    SortCaseSensitive=false
    SortColumn=name
    SortFolderFirst=true
    SortHiddenLast=false
    SortOrder=ascending
    ThumbnailIconSize=128

    [Places]
    HiddenPlaces=@Invalid()

    [Search]
    MaxSearchHistory=0
    searchContentCaseInsensitive=false
    searchContentRegexp=true
    searchNameCaseInsensitive=false
    searchNameRegexp=true
    searchRecursive=false
    searchhHidden=true

    [System]
    Archiver=org.kde.ark
    FallbackIconThemeName=Papirus-Dark
    OnlyUserTemplates=false
    SIUnit=false
    Terminal=foot

    [Thumbnail]
    MaxExternalThumbnailFileSize=-1
    MaxThumbnailFileSize=4096
    ShowThumbnails=false
    ThumbnailLocalFilesOnly=true

    [Volume]
    AutoRun=true
    CloseOnUnmount=true
    MountOnStartup=true
    MountRemovable=true

    [Window]
    AlwaysShowTabs=true
    PathBarButtons=true
    RememberWindowSize=true
    ReopenLastTabs=false
    ShowMenuBar=true
    ShowTabClose=true
    SidePaneMode=places
    SidePaneVisible=true
    SplitView=false
    SidePaneIconSize=24
    SplitterPos=180
  '';

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
      "inode/directory" = nautilus;
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

  xdg.configFile."pcmanfm-qt/default/settings.conf".text = pcmanfmQtSettings;
  xdg.configFile."pcmanfm-qt/lxqt/settings.conf".text = pcmanfmQtSettings;

  xdg.configFile."libfm/libfm.conf".text = ''
    [config]
    single_click=0
    use_trash=1
    confirm_del=1
    terminal=foot

    [ui]
    show_hidden=1
  '';


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
