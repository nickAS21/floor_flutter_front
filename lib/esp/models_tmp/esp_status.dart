/// Системні стани роботи шлюзу ESP/BL602
enum EspState {
  disconnected,
  connecting,
  standby,
  active,
  provisioning,
  error,
}

/// Модель статусу шлюзу
class EspStatus {
  final EspState state;
  final String? ipAddress;
  final int? freeHeap;
  final String? errorMessage;

  const EspStatus({
    this.state = EspState.disconnected,
    this.ipAddress,
    this.freeHeap,
    this.errorMessage,
  });
}