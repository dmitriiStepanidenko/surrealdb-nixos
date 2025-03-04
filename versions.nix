{
  v2_2_0 = {
    version = "2.2.0";
    srcHash = "sha256-gsIeoxSfbHHSdpPn6xAB/t5w3cLtpu6MjTuf5xsI6wI=";
    cargoHash = "sha256-OXcQsDCiT3seMQhyKEKfC8pcd4MXwbql5+ZDGGkhPMI=";
    rocksdb = pkgs: pkgs.rocks;
  };

  v2_0_2 = {
    version = "2.0.2";
    srcHash = "sha256-kTTZx/IXXJrkC0qm4Nx0hYPbricNjwFshCq0aFYCTo0="; 
    cargoHash = "sha256-K62RqJqYyuAPwm8zLIiASH7kbw6raXS6ZzINMevWav0="; 
    #rocksdb = pkgs: pkgs.rocks_8_11;
    rocksdb = pkgs: pkgs.rocks;
  };
}
