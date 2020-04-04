// import 'package:flutter_data/flutter_data.dart';
// import 'package:recase/recase.dart';

// mixin StandardJSONAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
//   @override
//   get headers => {'Content-Type': 'application/json'};

//   String get identifier => 'id';
//   String get identifierSuffix => '_id';

//   String serializeKey(String key) => ReCase(key).snakeCase;
//   String deserializeKey(String key) => ReCase(key).camelCase;

//   // Transforms JSON:API into standard JSON
//   @override
//   dynamic serialize(Map<String, dynamic> json) {
//     Map<String, dynamic> map;
//     var data = json['data'];
//     if (data is Map) {
//       map = {
//         ...{identifier: data['id']},
//         ...data['attributes'].map((key, attr) {
//           return MapEntry(serializeKey(key.toString()), attr);
//         }),
//         ...?data['relationships']?.map((k, v) {
//           var key = serializeKey(k.toString());
//           var relData = v['data'];
//           if (relData is List) {
//             return MapEntry(key, relData.map((e) => e[identifier]));
//           } else {
//             return MapEntry(key, relData[identifier]);
//           }
//         })
//       };
//     }
//     return map;
//   }

//   // Transforms standard JSON into JSON:API
//   // TODO could it be constructed from json-api-dart classes instead?
//   @override
//   Map<String, dynamic> deserialize(dynamic json,
//       [Map<String, dynamic> relationshipMetadata]) {
//     dynamic primaryData;
//     final includes = [];

//     if (json is List) {
//       primaryData = json
//           .map((e) => _buildPrimaryData(
//                 e as Map<String, dynamic>,
//                 relationshipMetadata,
//                 type,
//               ))
//           .toList();
//       includes.addAll((primaryData as List).map((e) => e));
//     } else if (json is Map<String, dynamic>) {
//       primaryData = _buildPrimaryData(json, relationshipMetadata, type);
//       includes.addAll(primaryData.remove('included') as Iterable);
//     }

//     return super.deserialize({'data': primaryData, 'included': includes});
//   }

//   Map<String, dynamic> _buildPrimaryData(Map<String, dynamic> json,
//       Map<String, dynamic> relationshipMetadata, String type) {
//     dynamic id;
//     final attributes = <String, Object>{};
//     final relationships = <String, Object>{};
//     final included = [];

//     final hasManys =
//         Map<String, String>.from(relationshipMetadata['HasMany'] as Map);
//     final belongsTos =
//         Map<String, String>.from(relationshipMetadata['BelongsTo'] as Map);

//     for (var entry in json.entries) {
//       var belongsToKey =
//           entry.key.replaceFirst(RegExp('$identifierSuffix\\b'), "");
//       var newKey = deserializeKey(entry.key);

//       if (hasManys.containsKey(entry.key)) {
//         relationships[newKey] = {
//           'data': (entry.value as Iterable).map(
//             (e) {
//               var _isIncluded = e is Map;
//               if (_isIncluded) {
//                 included.add(_buildPrimaryData(
//                   e as Map<String, dynamic>,
//                   relationshipMetadata,
//                   hasManys[entry.key],
//                 ));
//               }
//               return _buildLinkage(
//                 (_isIncluded ? e[identifier] : e).toString(),
//                 hasManys[entry.key],
//               );
//             },
//           ).toList()
//         };
//       } else if (belongsTos.containsKey(belongsToKey)) {
//         var _isIncluded = entry.value is Map;
//         if (_isIncluded) {
//           included.add(_buildPrimaryData(
//             entry.value as Map<String, dynamic>,
//             relationshipMetadata,
//             belongsTos[belongsToKey],
//           ));
//         }
//         relationships[deserializeKey(belongsToKey)] = {
//           'data': _buildLinkage(
//             (_isIncluded ? entry.value[identifier] : entry.value).toString(),
//             belongsTos[belongsToKey],
//           )
//         };
//       } else if (entry.key == identifier) {
//         id = entry.value.toString();
//       } else {
//         // attributes
//         attributes[newKey] = entry.value;
//       }
//     }
//     return {
//       'id': id,
//       'type': type,
//       'attributes': attributes,
//       'relationships': relationships,
//       'included': included
//     };
//   }

//   _buildLinkage(id, type) {
//     return {'id': id, 'type': type};
//   }
// }
