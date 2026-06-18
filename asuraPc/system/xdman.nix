{
  lib,
  pkgs,
  stdenv,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  ffmpeg,
  gtk3,
  lttng-ust_2_12,
  openssl,
}:

stdenv.mkDerivation rec {
  pname = "xdm";
  version = "8.0.29";

  src = pkgs.fetchurl {
    url = "https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk_8.0.29_amd64.deb";
    sha256 = "04cydd5i94qbnsi2535mswapng6hbwc567jhzbq8s715n0nvnn9n";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    ffmpeg
    gtk3
    lttng-ust_2_12
    openssl
    pkgs.adwaita-icon-theme
  ];

  unpackPhase = "true";

  installPhase = ''
    dpkg-deb --extract $src $TMPDIR

    mkdir -p $out/bin
    mkdir -p $out/share/applications/
    mkdir -p $out/share/icons/hicolor/scalable/apps/

    cp -av $TMPDIR/usr/bin/xdman $out/bin/
    cp -av $TMPDIR/usr/share/applications/xdm-app.desktop $out/share/applications/
    cp -av $TMPDIR/opt/xdman/xdm-logo.svg $out/share/icons/hicolor/scalable/apps/
    cp -av $TMPDIR/opt/xdman/* $out/

    rm -rf $TMPDIR/*

    sed -i "s|/opt/xdman/xdm-app|$out/xdm-app|g" $out/bin/xdman
    sed -i "s|/opt/xdman/xdm-app|$out/bin/xdman|g" $out/share/applications/xdm-app.desktop
    sed -i "s|/opt/xdman/xdm-logo.svg|$out/share/icons/hicolor/scalable/apps/xdm-logo.svg|g" $out/share/applications/xdm-app.desktop

    find $out -type d -exec chmod 755 {} +
    find $out -type f -exec chmod 644 {} +

    chmod +x $out/bin/xdman
    chmod +x $out/xdm-app
    chmod +x $out/share/applications/xdm-app.desktop

    wrapProgram $out/xdm-app \
      --prefix LD_LIBRARY_PATH : "${gtk3.out}/lib:${openssl.out}/lib" \
      --set GTK_USE_PORTAL 1

    wrapProgram $out/bin/xdman \
      --prefix LD_LIBRARY_PATH : "${gtk3.out}/lib:${openssl.out}/lib"
  '';

  meta = with lib; {
    description = "Powerful download accelerator and video downloader";
    homepage = "https://github.com/subhra74/xdm";
    license = licenses.gpl2Only;
    mainProgram = "xdman";
    platforms = [ "x86_64-linux" ];
  };
}
