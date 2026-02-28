enum PowerType {
  GRID("grid"),
  SOLAR("solar"),
  BATTERY("battery");

  final String description;
  const PowerType(this.description);

  String get apiValue => name; // Повертає "GRID", "SOLAR" і т.д.
}

enum ViewMode { day, month, year }