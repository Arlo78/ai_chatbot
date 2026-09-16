import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState()) {
    loadAvatar();
  }

  static const _avatarPreferenceKey = 'user_avatar';

  Future<void> loadAvatar() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedAvatar = preferences.getString(_avatarPreferenceKey);
    if (encodedAvatar == null || isClosed) return;

    try {
      emit(ProfileState(avatarBytes: base64Decode(encodedAvatar)));
    } on FormatException {
      await preferences.remove(_avatarPreferenceKey);
    }
  }

  Future<void> setAvatar(Uint8List avatarBytes) async {
    emit(ProfileState(avatarBytes: avatarBytes));

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _avatarPreferenceKey,
      base64Encode(avatarBytes),
    );
  }

  Future<void> removeAvatar() async {
    emit(const ProfileState());

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_avatarPreferenceKey);
  }
}
