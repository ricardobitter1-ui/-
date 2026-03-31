import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/title_search_key.dart';

// Sentinel para distinguir 'não passou' de 'passou null' em copyWith
const _unset = Object();

class TaskModel {
  final String id;
  final String title;
  /// Derivado do [title] para queries (`where('titleSearchKey', ...)`); minúsculas, sem acentos.
  final String titleSearchKey;
  final String description;
  final double? latitude;
  final double? longitude;
  /// Raio do geofence em metros (lembrete por localização). Padrão efetivo 100 se null em tarefas antigas.
  final double? geofenceRadiusMeters;
  /// Rótulo opcional para exibição (ex.: nome do lugar); não afeta o SO.
  final String? locationLabel;
  final bool isCompleted;

  final String? reminderType; // 'datetime' ou 'location' ou null
  final DateTime? dueDate;
  final String? locationTrigger;

  final String? ownerId;
  final String? groupId;
  /// Criador da tarefa (útil em tarefas de grupo).
  final String? createdBy;
  /// Responsáveis (subset de membros do grupo); vazio fora de grupo ou sem atribuição.
  final List<String> assigneeIds;
  /// Etiquetas do grupo (`groups/{groupId}/tags/`); vazio fora de grupo ou sem tags.
  final List<String> tagIds;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    String? resolvedSearchKey,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters,
    this.locationLabel,
    this.isCompleted = false,
    this.reminderType,
    this.dueDate,
    this.locationTrigger,
    this.ownerId,
    this.groupId,
    this.createdBy,
    this.assigneeIds = const [],
    this.tagIds = const [],
  }) : titleSearchKey = (resolvedSearchKey != null && resolvedSearchKey.isNotEmpty)
            ? resolvedSearchKey
            : normalizeTitleSearchKey(title);

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? geofenceRadiusMeters = _unset,
    Object? locationLabel = _unset,
    bool? isCompleted,
    Object? reminderType = _unset,
    Object? dueDate = _unset,
    Object? locationTrigger = _unset,
    Object? ownerId = _unset,
    Object? groupId = _unset,
    Object? createdBy = _unset,
    Object? assigneeIds = _unset,
    Object? tagIds = _unset,
  }) {
    final newTitle = title ?? this.title;
    return TaskModel(
      id: id ?? this.id,
      title: newTitle,
      description: description ?? this.description,
      resolvedSearchKey: normalizeTitleSearchKey(newTitle),
      latitude: identical(latitude, _unset) ? this.latitude : latitude as double?,
      longitude: identical(longitude, _unset) ? this.longitude : longitude as double?,
      geofenceRadiusMeters: identical(geofenceRadiusMeters, _unset)
          ? this.geofenceRadiusMeters
          : geofenceRadiusMeters as double?,
      locationLabel: identical(locationLabel, _unset)
          ? this.locationLabel
          : locationLabel as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderType: identical(reminderType, _unset) ? this.reminderType : reminderType as String?,
      dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
      locationTrigger: identical(locationTrigger, _unset) ? this.locationTrigger : locationTrigger as String?,
      ownerId: identical(ownerId, _unset) ? this.ownerId : ownerId as String?,
      groupId: identical(groupId, _unset) ? this.groupId : groupId as String?,
      createdBy: identical(createdBy, _unset) ? this.createdBy : createdBy as String?,
      assigneeIds: identical(assigneeIds, _unset) ? this.assigneeIds : assigneeIds as List<String>,
      tagIds: identical(tagIds, _unset) ? this.tagIds : tagIds as List<String>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'titleSearchKey': titleSearchKey,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'locationLabel': locationLabel,
      'isCompleted': isCompleted,
      'reminderType': reminderType,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'locationTrigger': locationTrigger,
      'ownerId': ownerId,
      'groupId': groupId,
      'createdBy': createdBy,
      'assigneeIds': assigneeIds,
      'tagIds': tagIds,
    };
  }
}
