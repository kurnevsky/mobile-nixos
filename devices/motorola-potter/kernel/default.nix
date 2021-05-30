{
  mobile-nixos
, stdenv
, fetchFromGitHub
, ...
}:


mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.113";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "boulzordev";
    repo = "android_kernel_motorola_msm8953";
    rev = "efeb95ed634079eb520922f6f78f16f9d967a6d4";
    sha256 = "03xmlyq06fvn0v4nvrs2nhmb88axg45ccd1vb3nam6jj1381zv4w";
  };

  patches = [
    ./04_fix_camera_msm_isp.patch
    ./99_framebuffer.patch
    ./0001-Allow-building-WCD9335_CODEC-without-REGMAP_ALLOW_WR.patch
    ./0005-Allow-building-with-sound-disabled.patch
    ./0007-Coalesce-identical-device-trees.patch
  ];

  enableRemovingWerror = true;
  isModular = false;
  isQcdt = true;
}
