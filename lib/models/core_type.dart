enum CoreType {
  xray,
  singbox,
  hysteria2;

  String get displayName {
    switch (this) {
      case CoreType.xray:
        return 'Xray';
      case CoreType.singbox:
        return 'sing-box';
      case CoreType.hysteria2:
        return 'Hysteria2';
    }
  }

  String get executableName {
    switch (this) {
      case CoreType.xray:
        return 'xray';
      case CoreType.singbox:
        return 'sing-box';
      case CoreType.hysteria2:
        return 'hysteria2';
    }
  }
}
