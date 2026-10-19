{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
  inherit (config.boot.initrd) luks;
  cfg = config.mobile.boot.stage-1.luks;
in

{
  options.mobile.boot.stage-1.luks = {
    reusePassphrases = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Try passphrases that successfully unlocked a LUKS device on the
        remaining LUKS devices before asking for a new passphrase.

        This allows unlocking multiple LUKS devices sharing the same
        passphrase with a single prompt.
      '';
    };
  };

  config = lib.mkIf (luks.devices != {} || luks.forceLuksSupportInInitrd) {
    mobile.boot.stage-1 = {
      bootConfig = {
        luksDevices = luks.devices;
        luksReusePassphrases = cfg.reusePassphrases;
      };
      kernel = {
        modules = [ "dm_mod" ];
        additionalModules = [
          "dm_mod" "dm_crypt" "cryptd" "input_leds"
        ] ++ luks.cryptoModules
        ;
      };

      extraUtils = [
        { package = pkgs.cryptsetup; }
        # dmsetup is required for device mapper stuff to work in stage-1.
        { package = lib.getBin pkgs.lvm2; binaries = [
          "lvm" "dmsetup"
        ];}
      ];
    };
  };
}
