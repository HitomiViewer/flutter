import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isIOS || Platform.isAndroid;
    }
  }

  static bool get isDesktop {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isLinux ||
          Platform.isFuchsia ||
          Platform.isWindows ||
          Platform.isMacOS;
    }
  }

  static bool get isWeb {
    return kIsWeb;
  }

  static bool get isIOS {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isIOS;
    }
  }

  static bool get isAndroid {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isAndroid;
    }
  }

  static bool get isLinux {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isLinux;
    }
  }

  static bool get isFuchsia {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isFuchsia;
    }
  }

  static bool get isWindows {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isWindows;
    }
  }

  static bool get isMacOS {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isMacOS;
    }
  }
}
