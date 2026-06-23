{
  lib,
  pkgs,
  stdenvNoCC,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
}:

let
  runtimeLibs = with pkgs; [
    atk
    cairo
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    libnotify
    librsvg
    lttng-ust_2_12
    openssl
    pango
    stdenv.cc.cc.lib
    zlib
    libx11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
  ];
in
stdenvNoCC.mkDerivation rec {
  pname = "xdman-gtk";
  version = "8.0.29";

  src = pkgs.fetchurl {
    url = "https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk_8.0.29_amd64.deb";
    hash = "sha256-Nlm7LbAlHI3w+lAeUxhf0Dx7Fde1jCKitguTFEtrnhE=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = runtimeLibs;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/applications/
    mkdir -p $out/share/icons/hicolor/scalable/apps/
    mkdir -p $out/share/pixmaps

    cp -av source/usr/bin/xdman $out/bin/
    cp -av source/usr/share/applications/xdm-app.desktop $out/share/applications/
    cp -av source/opt/xdman/. $out/
    cp -av source/opt/xdman/xdm-logo.svg $out/share/icons/hicolor/scalable/apps/
    ln -sf $out/share/icons/hicolor/scalable/apps/xdm-logo.svg $out/share/pixmaps/xdm-logo.svg

    sed -i "s|/opt/xdman/xdm-app|$out/xdm-app|g" $out/bin/xdman
    substituteInPlace $out/share/applications/xdm-app.desktop \
      --replace-fail "env GTK_USE_PORTAL=1 /opt/xdman/xdm-app" "$out/bin/xdman" \
      --replace-fail "/opt/xdman/xdm-logo.svg" "$out/share/icons/hicolor/scalable/apps/xdm-logo.svg"
    substituteInPlace $out/share/applications/xdm-app.desktop \
      --replace-fail "MimeType=application/xdm-app;x-scheme-handler/xdm-app;" \
      "MimeType=application/xdm-app;x-scheme-handler/xdm-app;x-scheme-handler/xdm+app;"
    substituteInPlace $out/share/applications/xdm-app.desktop \
      --replace-fail "Categories=Network;" "Categories=Network;FileTransfer;GTK;" \
      --replace-fail "StartupNotify=true" "StartupNotify=false"
    printf '%s\n' \
      'StartupWMClass=xdm-app' \
      'DBusActivatable=false' \
      >> $out/share/applications/xdm-app.desktop

    find $out -type d -exec chmod 755 {} +
    find $out -type f -exec chmod 644 {} +

    chmod +x $out/bin/xdman
    chmod +x $out/xdm-app
    chmod +x $out/share/applications/xdm-app.desktop

    wrapProgram $out/xdm-app \
      --set GTK_USE_PORTAL 1 \
      --set GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

    wrapProgram $out/bin/xdman \
      --set GTK_USE_PORTAL 1 \
      --set GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Powerful download accelerator and video downloader";
    homepage = "https://github.com/subhra74/xdm";
    license = licenses.gpl2Plus;
    mainProgram = "xdman";
    platforms = [ "x86_64-linux" ];
  };
}
