enum LocationType {
  dacha("Dacha"),
  golego("Golego");

  final String label;
  const LocationType(this.label);

  String get apiValue => name.toUpperCase();
}
