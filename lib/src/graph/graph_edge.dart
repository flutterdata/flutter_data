part of flutter_data;

class _GraphEdge extends DataModel<_GraphEdge> {
  @override
  int? id;
  final String from;
  final String to;
  final String? _metadata;
  final bool inverted;

  String? get metadata => _metadata?.split('#').first;
  String? get inverseMetadata => _metadata?.split('#').last;

  _GraphEdge(
    this.from,
    this.to, {
    String? metadata,
    String? inverseMetadata,
    this.inverted = false,
  }) : _metadata = '$metadata#$inverseMetadata';

  _GraphEdge invert() {
    return _GraphEdge(to, from,
        metadata: inverseMetadata,
        inverseMetadata: metadata,
        inverted: !inverted);
  }

  @override
  String toString() {
    return 'GraphEdge(id: $id, from: $from, to: $to, metadata: $metadata, inverseMetadata: $inverseMetadata, inverted: $inverted)';
  }
}

mixin _$GraphEdgeLocalAdapter on LocalAdapter<_GraphEdge> {
  static final Map<String, FieldMeta> _kGraphEdgeFieldMetas = {
    // IMPORTANT: keep them in alphabetic order!
    'from': AttributeMeta<_GraphEdge>(
      name: 'from',
      type: 'String',
      nullable: false,
      internalType: 'String',
      index: 'from',
    ),
    'metadata': AttributeMeta<_GraphEdge>(
      name: 'metadata',
      type: 'String',
      nullable: true,
      internalType: 'String',
    ),
    'to': AttributeMeta<_GraphEdge>(
      name: 'to',
      type: 'String',
      nullable: false,
      internalType: 'String',
      index: 'to',
    ),
  };

  @override
  Map<String, FieldMeta> get fieldMetas => _kGraphEdgeFieldMetas;

  @override
  _GraphEdge deserialize(map) {
    final metadata = (map['metadata'] as String?)?.split('#');
    return _GraphEdge(map['from'] as String, map['to'] as String,
        metadata: metadata!.first, inverseMetadata: metadata.last);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    return {
      'from': model.from,
      'to': model.to,
      'metadata': model._metadata,
    };
  }
}

class _GraphEdgeLocalAdapter = IsarLocalAdapter<_GraphEdge>
    with _$GraphEdgeLocalAdapter;
