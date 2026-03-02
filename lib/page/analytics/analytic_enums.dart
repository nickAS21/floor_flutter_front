enum PowerType {
  GRID("grid"),
  SOLAR("solar"),
  BATTERY("battery");

  final String description;
  const PowerType(this.description);

  String get apiValue => name.toUpperCase(); // Повертає "GRID", "SOLAR" і т.д.
}

enum ViewMode { day, month, year, period }