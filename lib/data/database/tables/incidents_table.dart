import 'package:drift/drift.dart';

/// Drift table definition for reported incidents.
@DataClassName('IncidentData')
class Incidents extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Incident type string ('police', 'accident', 'trafficHeavy').
  TextColumn get type => text()();

  /// Latitude coordinate where incident occurred.
  RealColumn get latitude => real()();

  /// Longitude coordinate where incident occurred.
  RealColumn get longitude => real()();

  /// Unix timestamp in milliseconds when the incident was reported.
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
