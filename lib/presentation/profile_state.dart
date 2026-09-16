import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  const ProfileState({this.avatarBytes});

  final Uint8List? avatarBytes;

  @override
  List<Object?> get props => [avatarBytes];
}
