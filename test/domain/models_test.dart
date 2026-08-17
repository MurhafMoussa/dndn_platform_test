import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/user_role.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';

void main() {
  group('Domain Failures Hierarchy', () {
    test('LocationPermissionDeniedFailure instantiation and equality props', () {
      final failure1 = LocationPermissionDeniedFailure(
        message: 'Permission denied',
        isPermanentlyDenied: false,
      );
      final failure2 = LocationPermissionDeniedFailure(
        message: 'Permission denied',
        isPermanentlyDenied: false,
      );
      final failure3 = LocationPermissionDeniedFailure(
        message: 'Permission denied',
        isPermanentlyDenied: true,
      );

      expect(failure1.message, equals('Permission denied'));
      expect(failure1.isPermanentlyDenied, isFalse);
      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
      expect(failure1.props, containsAll(['Permission denied', false, null]));
    });

    test('LocationServiceDisabledFailure default message and props', () {
      const failure = LocationServiceDisabledFailure();
      expect(failure.message, equals('GPS location services are disabled on device.'));
      expect(failure.props, equals(['GPS location services are disabled on device.', null]));
    });

    test('DatabaseFailure properties and equality', () {
      const cause = 'SQLite exception';
      const failure1 = DatabaseFailure('Failed to insert record', cause);
      const failure2 = DatabaseFailure('Failed to insert record', cause);

      expect(failure1.message, equals('Failed to insert record'));
      expect(failure1.cause, equals(cause));
      expect(failure1, equals(failure2));
    });

    test('SyncFailure properties and equality', () {
      const failure1 = SyncFailure('Network dispatch error');
      const failure2 = SyncFailure('Network dispatch error');

      expect(failure1.message, equals('Network dispatch error'));
      expect(failure1, equals(failure2));
    });

    test('UnauthorizedAccessFailure default message and equality', () {
      const failure1 = UnauthorizedAccessFailure();
      const failure2 = UnauthorizedAccessFailure();

      expect(failure1.message, equals('Access restricted to administrator sessions only.'));
      expect(failure1, equals(failure2));
    });

    test('DistanceCalculationFailure properties and equality', () {
      const failure1 = DistanceCalculationFailure('Insufficient points');
      const failure2 = DistanceCalculationFailure('Insufficient points');

      expect(failure1.message, equals('Insufficient points'));
      expect(failure1, equals(failure2));
    });
  });

  group('Domain Models & Enums', () {
    test('UserRole values and instantiation', () {
      expect(UserRole.values, containsAll([UserRole.user, UserRole.admin]));
      expect(UserRole.user.name, equals('user'));
      expect(UserRole.admin.name, equals('admin'));
    });

    test('LocationPoint instantiation and Equatable equality', () {
      final now = DateTime.now();
      final point1 = LocationPoint(
        id: 'loc-1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );
      final point2 = LocationPoint(
        id: 'loc-1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );
      final point3 = LocationPoint(
        id: 'loc-2',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      expect(point1.id, equals('loc-1'));
      expect(point1.latitude, equals(37.7749));
      expect(point1.longitude, equals(-122.4194));
      expect(point1.timestamp, equals(now));
      expect(point1, equals(point2));
      expect(point1, isNot(equals(point3)));
    });

    test('IncidentReport instantiation, IncidentType enum and Equatable equality', () {
      final now = DateTime.now();
      expect(IncidentType.values, containsAll([
        IncidentType.police,
        IncidentType.accident,
        IncidentType.trafficHeavy,
      ]));

      final incident1 = IncidentReport(
        id: 'inc-1',
        type: IncidentType.police,
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );
      final incident2 = IncidentReport(
        id: 'inc-1',
        type: IncidentType.police,
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      expect(incident1.id, equals('inc-1'));
      expect(incident1.type, equals(IncidentType.police));
      expect(incident1, equals(incident2));
    });

    test('SyncOutboxItem instantiation, SyncStatus enum and Equatable equality', () {
      final now = DateTime.now();
      expect(SyncStatus.values, containsAll([
        SyncStatus.pending,
        SyncStatus.syncing,
        SyncStatus.synced,
        SyncStatus.failed,
      ]));

      final item1 = SyncOutboxItem(
        id: 'box-1',
        eventType: 'location_point_created',
        payload: '{"id": "loc-1"}',
        createdAt: now,
        status: SyncStatus.pending,
      );
      final item2 = SyncOutboxItem(
        id: 'box-1',
        eventType: 'location_point_created',
        payload: '{"id": "loc-1"}',
        createdAt: now,
        status: SyncStatus.pending,
      );

      expect(item1.id, equals('box-1'));
      expect(item1.eventType, equals('location_point_created'));
      expect(item1.status, equals(SyncStatus.pending));
      expect(item1, equals(item2));
    });
  });
}
