# Android, Waydroid, and QR transfer tooling.
{ pkgs, ... }:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "36"
      "35"
    ];
    buildToolsVersions = [
      "36.0.0"
      "35.0.0"
    ];
    includeSources = true;
    includeSystemImages = false;
    includeEmulator = true;
    includeNDK = true;
    ndkVersions = [ "27.2.12479018" ];
  };

  androidSdk = androidComposition.androidsdk;
  androidSdkPath = "${androidSdk}/libexec/android-sdk";
  androidNdkPath = "${androidSdkPath}/ndk-bundle";

  androidStudioWithSdk = pkgs.symlinkJoin {
    name = "android-studio-with-sdk";
    paths = [ pkgs.android-studio ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/android-studio"
      makeWrapper ${pkgs.android-studio}/bin/android-studio "$out/bin/android-studio" \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.android-tools
            pkgs.jdk17
            pkgs.gradle
          ]
        } \
        --set ANDROID_SDK_ROOT ${androidSdkPath} \
        --set ANDROID_HOME ${androidSdkPath} \
        --set ANDROID_NDK_ROOT ${androidNdkPath} \
        --set JAVA_HOME ${pkgs.jdk17}
    '';
  };

  androidLocalProperties = pkgs.writeShellScriptBin "android-local-properties" ''
    set -euo pipefail

    target="''${1:-local.properties}"
    cat > "$target" <<EOF
    sdk.dir=${androidSdkPath}
    ndk.dir=${androidNdkPath}
    EOF

    printf 'Wrote %s\n' "$target"
  '';

  androidEnvInfo = pkgs.writeShellScriptBin "android-env-info" ''
    cat <<'EOF'
    Android development paths
      Android Studio: android-studio
      SDK root:       ${androidSdkPath}
      NDK root:       ${androidNdkPath}
      ADB:            ${pkgs.android-tools}/bin/adb
      Fastboot:       ${pkgs.android-tools}/bin/fastboot
      Java:           ${pkgs.jdk17}/bin/java

    Project helper
      android-local-properties
      android-local-properties /path/to/project/local.properties

    Wireless debugging helpers
      adb-reset
      adb-wifi-connect PHONE_IP:CONNECT_PORT

    Waydroid
      sudo waydroid init
      waydroid session start
      waydroid show-full-ui

    QR transfer
      qrcp FILE_OR_DIR
      qrencode -t ansiutf8 'text'
      qrtool decode image.png
    EOF
  '';
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  virtualisation.waydroid.enable = true;

  environment.sessionVariables = {
    ANDROID_SDK_ROOT = androidSdkPath;
    ANDROID_HOME = androidSdkPath;
    ANDROID_NDK_ROOT = androidNdkPath;
    JAVA_HOME = "${pkgs.jdk17}";
  };

  environment.systemPackages = with pkgs; [
    androidStudioWithSdk
    androidSdk
    jdk17
    gradle
    waydroid-helper
    qrcp
    qrencode
    qrtool
    androidLocalProperties
    androidEnvInfo
  ];
}
