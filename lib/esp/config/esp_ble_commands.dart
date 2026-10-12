/// Базовий контракт для команд, що надсилаються на ESP/BL по BLE
abstract class EspBleCommands {}

/// Реалізація команд для BL602
class Bl602BleCommands implements EspBleCommands {}