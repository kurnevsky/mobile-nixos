{ config, lib, pkgs, ... }:

let
  # This is not a secure or safe way to create an encrypted drive in a build.
  # This is SOLELY for testing purposes.
  passphrase = "1234";
  uuid = "12345678-1234-1234-1234-123456789abc"; # heh

  # We are re-using the raw filesystem from the hello system.
  rootfsExt4 = (
    import ../../hello { device = config.mobile.device.name; }
  ).build.rootfs;

  # This is not a facility from the disk images builder because **it is really
  # insecure to use**.
  # So, for now, we have an implementation details-y way of producing an
  # encrypted rootfs.
  encryptedRootfs =
    pkgs.runCommand "encrypted-rootfs" {
      buildInputs = [ pkgs.cryptsetup ];
      passthru = {
        filename = "encrypted.img";
        filesystemType = "LUKS";
      };
    } ''
    mkdir -p $out

    export slack=32 # MiB

    # Some slack space we'll append to the raw fs
    # Used by `--reduce-device-size` read cryptsetup(8).
    dd if=/dev/zero of=/tmp/slack.img bs=1024 count=$((slack*1024))

    # Catting both to ensure it's writable, and to add some slack space at
    # the end
    cat ${rootfsExt4}/${rootfsExt4.label}.img /tmp/slack.img > /tmp/encrypted.img
    rm /tmp/slack.img

    ${pkgs.bubblewrap}/bin/bwrap \
      --ro-bind /nix/store /nix/store \
      --dev-bind /dev/random /dev/random \
      --dev-bind /dev/urandom /dev/urandom \
      --tmpfs /run/cryptsetup \
      --bind /tmp/encrypted.img /tmp/encrypted.img \
      ${pkgs.bash}/bin/bash -c '
        ${pkgs.coreutils}/bin/echo ${
          builtins.toJSON passphrase
        } | ${pkgs.cryptsetup}/bin/cryptsetup reencrypt \
          --encrypt /tmp/encrypted.img \
          --reduce-device-size $((slack*1024*1024))

        ${pkgs.cryptsetup}/bin/cryptsetup luksUUID \
          --uuid=${builtins.toJSON uuid} \
          /tmp/encrypted.img
      '

    mv /tmp/encrypted.img $out/
    '';
in

{
  boot.initrd.luks.devices = {
    LUKS-MOBILE-ROOTFS = {
      device = "/dev/disk/by-uuid/${uuid}";
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/LUKS-MOBILE-ROOTFS";
      fsType = "ext4";
    };
  };

  # Instead of the (mkDefault) rootfs, provide our raw encrypted rootfs.
  mobile.generatedFilesystems.rootfs = {
    raw = encryptedRootfs;
  };
}
