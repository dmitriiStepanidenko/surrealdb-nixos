{
  "2.2.0" = import ./binary/2.2.0.nix;
  "2_2_0" = import ./binary/2.2.0.nix;
  "2.2.1" = import ./binary/2.2.1.nix;
  "2_2_1" = import ./binary/2.2.1.nix;
  "2.2.2" = import ./binary/2.2.2.nix;
  "2_2_2" = import ./binary/2.2.2.nix;
  "2.3.0" = import ./binary/2.3.0.nix;
  "2_3_0" = import ./binary/2.3.0.nix;
  "2.3.1" = import ./binary/2.3.1.nix;
  "2_3_1" = import ./binary/2.3.1.nix;
  "3.0.0-alpha.1" = import ./binary/3.0.0-alpha.1.nix;
  "3_0_0-alpha_1" = import ./binary/3.0.0-alpha.1.nix;
  "3.0.0-alpha.2" = import ./binary/3.0.0-alpha.2.nix;
  "3_0_0-alpha_2" = import ./binary/3.0.0-alpha.2.nix;
  "3.0.0-alpha.3" = import ./binary/3.0.0-alpha.3.nix;
  "3_0_0-alpha_3" = import ./binary/3.0.0-alpha.3.nix;
  latest = import ./binary/2.3.1.nix;
  latest_unstable = import ./binary/3.0.0-alpha.3.nix;
}
