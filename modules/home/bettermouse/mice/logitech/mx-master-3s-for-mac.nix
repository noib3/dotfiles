{ config, lib, ... }:

{
  options = {
    ratchetMode = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to use ratchet mode for the scroll wheel";
      default = true;
    };
  };

  config = {
    buttons = {
      wheel.buttonId = 2;
      thumb.buttonId = 5;
      # TODO: add other buttons as we discover their IDs.
    };

    # TODO: add options to configure more parameters instead of hardcoding them.
    asBetterMouseFormat = {
      name = {
        vendor = "Logitech";
        product = "MX Master 3S M";
      };
      optCsr = {
        en = false;
        acc = [
          68.75
          0.0
        ];
        res = [
          5.0
          25.0
        ];
      };
      dpiEn = false;
      dpiIndex = 0;
      ratchetMode = config.ratchetMode;
      disengagePoint = 11;
      torque = 50;
      hiResWheel = false;
      pressure = 4261;
      haptic = [
        0
        0
        0
        0
      ];
      pattern = [
        0
        0
        0
        0
      ];
      patternEn = [
        false
        false
        false
        false
      ];
      twUsage = {
        Zoom = { };
      };
      twDirInv = [
        { Zoom = { }; }
        false
        { VScroll = { }; }
        false
        { HScroll = { }; }
        false
        { Button = { }; }
        false
        { None = { }; }
        false
      ];
      twSpeed = [
        { VScroll = { }; }
        1.0
        { HScroll = { }; }
        1.0
        { None = { }; }
        1.0
        { Button = { }; }
        1.0
        { Zoom = { }; }
        1.0
      ];
      OnboardProfileEn = false;
      quirks = [
        196
        true
        195
        true
      ];
      rpRateList = 8;
      rpRate = 0;
      featureMap = {
        "0" = 9;
        "1" = 14;
        "2" = 16;
        "4" = 13;
        "5" = 15;
        "10" = 8;
      };
      featureCompleted = false;
    };
  };
}
