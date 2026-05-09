import 'package:hive/hive.dart';
import 'package:api/src/models/.dart';

part '.cm.g.dart';

@HiveType(typeId: 0)
class CM extends HiveObject {


   toDto() => (

      );

  factory CM.fromDto( dto) =>
      CM()
;
}
