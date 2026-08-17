import 'package:drift/drift.dart';

/// Drift table definition for recorded GPS location points.
@DataClassName('LocationPointData')
class LocationPoints extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Latitude coordinate value.
  RealColumn get latitude => real()();

  /// Longitude coordinate value.
  RealColumn get longitude => real()();

  /// Unix timestamp in milliseconds when the point was captured.
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
