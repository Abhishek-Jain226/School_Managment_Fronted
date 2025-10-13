enum TripType {
  morningPickup('MORNING_PICKUP', 'Morning Pickup'),
  afternoonDrop('AFTERNOON_DROP', 'Afternoon Drop'),
  specialTrip('SPECIAL_TRIP', 'Special Trip'),
  fieldTrip('FIELD_TRIP', 'Field Trip');

  const TripType(this.value, this.displayName);

  final String value;
  final String displayName;

  static TripType fromValue(String value) {
    return TripType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TripType.morningPickup,
    );
  }

  static List<Map<String, String>> getDropdownItems() {
    return TripType.values.map((type) => {
      'value': type.value,
      'label': type.displayName,
    }).toList();
  }
}
