// Web stub for permission_handler
class Permission {
  static final bluetooth        = Permission._();
  static final bluetoothConnect = Permission._();
  static final bluetoothScan    = Permission._();
  static final locationWhenInUse= Permission._();
  Permission._();
  Future<PermissionStatus> request() async => PermissionStatus._();
}

class PermissionStatus {
  PermissionStatus._();
  bool get isGranted => false;
  bool get isLimited => false;
}

extension PermissionListX on List<Permission> {
  Future<Map<Permission, PermissionStatus>> request() async => {};
}
