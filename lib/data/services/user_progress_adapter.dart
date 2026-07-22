import 'package:hive/hive.dart';

import '/domain/models/user_progress.dart';

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 0;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return UserProgress(
      currentLevel: fields[0] as int? ?? 1,
      highestLevelCompleted: fields[1] as int? ?? 0,
      totalMoves: fields[2] as int? ?? 0,
      bestMoves: _readIntMap(fields[3]),
      bestTimeSeconds: _readIntMap(fields[4]),
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.currentLevel);
    writer.writeByte(1);
    writer.write(obj.highestLevelCompleted);
    writer.writeByte(2);
    writer.write(obj.totalMoves);
    writer.writeByte(3);
    writer.write(obj.bestMoves);
    writer.writeByte(4);
    writer.write(obj.bestTimeSeconds);
  }

  Map<int, int> _readIntMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key as int, value as int));
    }
    return const {};
  }
}
