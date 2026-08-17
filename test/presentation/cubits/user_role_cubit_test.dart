import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:dndn_platform_test/domain/models/user_role.dart';
import 'package:dndn_platform_test/presentation/cubits/user_role_cubit.dart';

class MockStorage implements Storage {
  final Map<String, dynamic> _storage = {};

  @override
  dynamic read(String key) => _storage[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<void> close() async {}
}

void main() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    HydratedBloc.storage = storage;
  });

  group('UserRoleCubit', () {
    test('initial state defaults to UserRole.user', () {
      final cubit = UserRoleCubit();
      expect(cubit.state, equals(UserRole.user));
    });

    test('setRole updates state to specified role', () {
      final cubit = UserRoleCubit();
      
      cubit.setRole(UserRole.admin);
      expect(cubit.state, equals(UserRole.admin));

      cubit.setRole(UserRole.user);
      expect(cubit.state, equals(UserRole.user));
    });

    test('toggleRole toggles between UserRole.user and UserRole.admin', () {
      final cubit = UserRoleCubit();

      cubit.toggleRole();
      expect(cubit.state, equals(UserRole.admin));

      cubit.toggleRole();
      expect(cubit.state, equals(UserRole.user));
    });

    test('toJson serializes UserRole correctly', () {
      final cubit = UserRoleCubit();

      expect(cubit.toJson(UserRole.user), equals({'role': 'user'}));
      expect(cubit.toJson(UserRole.admin), equals({'role': 'admin'}));
    });

    test('fromJson deserializes valid JSON map into UserRole', () {
      final cubit = UserRoleCubit();

      expect(cubit.fromJson({'role': 'admin'}), equals(UserRole.admin));
      expect(cubit.fromJson({'role': 'user'}), equals(UserRole.user));
    });

    test('fromJson handles missing or invalid JSON gracefully', () {
      final cubit = UserRoleCubit();

      expect(cubit.fromJson({}), equals(UserRole.user));
      expect(cubit.fromJson({'role': null}), equals(UserRole.user));
      expect(cubit.fromJson({'role': 'invalid_role'}), equals(UserRole.user));
    });

    test('restores state from HydratedStorage on creation', () {
      // Simulate existing saved role state in storage
      storage.write('UserRoleCubit', {'role': 'admin'});

      final cubit = UserRoleCubit();
      expect(cubit.state, equals(UserRole.admin));
    });

    test('persists state changes to HydratedStorage', () {
      final cubit = UserRoleCubit();

      cubit.setRole(UserRole.admin);

      final saved = storage.read('UserRoleCubit') as Map<String, dynamic>?;
      expect(saved, equals({'role': 'admin'}));
    });
  });
}
