import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../domain/models/user_role.dart';

/// Manages active application user role state with persistent storage via [HydratedCubit].
class UserRoleCubit extends HydratedCubit<UserRole> {
  UserRoleCubit() : super(UserRole.user);

  /// Updates the current role to [role].
  void setRole(UserRole role) {
    emit(role);
  }

  /// Toggles the current user role between [UserRole.user] and [UserRole.admin].
  void toggleRole() {
    emit(state == UserRole.user ? UserRole.admin : UserRole.user);
  }

  @override
  UserRole? fromJson(Map<String, dynamic> json) {
    try {
      final roleName = json['role'] as String?;
      if (roleName == null) return UserRole.user;
      return UserRole.values.firstWhere(
        (role) => role.name == roleName,
        orElse: () => UserRole.user,
      );
    } catch (_) {
      return UserRole.user;
    }
  }

  @override
  Map<String, dynamic>? toJson(UserRole state) {
    return {'role': state.name};
  }
}
