/// Small helpers to read the API's JSON safely (ids may come as `id` or `_id`,
/// references may be populated objects or plain ids).
String readId(dynamic value) {
  if (value == null) return '';
  if (value is Map) return (value['id'] ?? value['_id'] ?? '').toString();
  return value.toString();
}

Map<String, dynamic>? asMap(dynamic value) => value is Map<String, dynamic>
    ? value
    : (value is Map ? Map<String, dynamic>.from(value) : null);

DateTime? readDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

double readDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

int readInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
