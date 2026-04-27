import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/workload_item_model.dart';

class WorkloadRemoteDatasource {
  WorkloadRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<List<WorkloadItemModel>> fetchWorkload(String organizationId) async {
    final labelMaps = await _fetchLabelMaps();

    try {
      final response = await _client
          .from('v_member_workload')
          .select()
          .eq('organization_id', organizationId)
          .order('load_ratio', ascending: false);

      return _mapWorkloadRows(
        response as List<dynamic>,
        positionMap: labelMaps.$1,
        divisionMap: labelMaps.$2,
      );
    } on PostgrestException catch (error) {
      if (!_isMissingView(error)) {
        rethrow;
      }
    }

    return _fetchWorkloadFallback(
      organizationId,
      positionMap: labelMaps.$1,
      divisionMap: labelMaps.$2,
    );
  }

  Future<List<WorkloadItemModel>> _fetchWorkloadFallback(
    String organizationId, {
    required Map<String, String> positionMap,
    required Map<String, String> divisionMap,
  }) async {
    final memberRows = await _client
        .from('members')
        .select(
          'id, organization_id, profile_id, position_code, division_code, weekly_capacity_hours, profiles(full_name)',
        )
        .eq('organization_id', organizationId)
        .eq('status', 'active');

    final memberIds = (memberRows as List<dynamic>)
        .map((rawMember) => (rawMember as Map<String, dynamic>)['id'] as String)
        .toList();

    final assignmentRows = memberIds.isEmpty
        ? const <dynamic>[]
        : await _client
            .from('task_assignments')
            .select(
                'member_id, allocation_hours, tasks(estimated_hours, status)')
            .inFilter('member_id', memberIds);

    final assignedHoursByMemberId = <String, int>{};
    for (final rawAssignment in assignmentRows) {
      final assignment = Map<String, dynamic>.from(rawAssignment as Map);
      final memberId = assignment['member_id'] as String?;
      if (memberId == null) {
        continue;
      }

      final allocationHours = (assignment['allocation_hours'] as num?)?.toInt();
      final task = _asMap(assignment['tasks']);
      final taskStatus = (task?['status'] as String? ?? '')
          .trim()
          .toLowerCase()
          .replaceAll('-', '_');

      if (taskStatus == 'done') {
        continue;
      }

      int taskHours = allocationHours ?? 0;
      if (allocationHours == null && task != null) {
        taskHours = (task['estimated_hours'] as num?)?.toInt() ?? 0;
      }

      assignedHoursByMemberId.update(
        memberId,
        (current) => current + taskHours,
        ifAbsent: () => taskHours,
      );
    }

    return memberRows.map((rawMember) {
      final member = Map<String, dynamic>.from(rawMember as Map);
      final profile = member['profiles'];
      String fullName = 'Tanpa Nama';

      if (profile is Map<String, dynamic>) {
        fullName = profile['full_name'] as String? ?? fullName;
      } else if (profile is List && profile.isNotEmpty) {
        final profileMap = Map<String, dynamic>.from(profile.first as Map);
        fullName = profileMap['full_name'] as String? ?? fullName;
      }

      final weeklyCapacityHours =
          (member['weekly_capacity_hours'] as num?)?.toInt() ?? 0;
      final assignedHours =
          assignedHoursByMemberId[member['id'] as String] ?? 0;
      final loadRatio =
          weeklyCapacityHours == 0 ? 0.0 : assignedHours / weeklyCapacityHours;

      return WorkloadItemModel(
        memberId: member['id'] as String,
        organizationId: member['organization_id'] as String? ?? '',
        profileId: member['profile_id'] as String? ?? '',
        fullName: fullName,
        positionCode: member['position_code'] as String?,
        positionLabel: positionMap[member['position_code'] as String? ?? ''],
        divisionCode: member['division_code'] as String?,
        divisionLabel: divisionMap[member['division_code'] as String? ?? ''],
        weeklyCapacityHours: weeklyCapacityHours,
        assignedHours: assignedHours,
        loadRatio: loadRatio,
        workloadStatus: _buildWorkloadStatus(
          weeklyCapacityHours: weeklyCapacityHours,
          loadRatio: loadRatio,
        ),
      );
    }).toList()
      ..sort((left, right) => right.loadRatio.compareTo(left.loadRatio));
  }

  List<WorkloadItemModel> _mapWorkloadRows(
    List<dynamic> rows, {
    required Map<String, String> positionMap,
    required Map<String, String> divisionMap,
  }) {
    return rows.map((rawRow) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final positionCode = row['position_code'] as String?;
      final divisionCode = row['division_code'] as String?;
      return WorkloadItemModel.fromJson({
        ...row,
        'position_label':
            positionCode == null ? null : positionMap[positionCode],
        'division_label':
            divisionCode == null ? null : divisionMap[divisionCode],
      });
    }).toList();
  }

  Future<(Map<String, String>, Map<String, String>)> _fetchLabelMaps() async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('position_templates')
          .select('code, label')
          .eq('is_active', true),
      _client
          .from('division_templates')
          .select('code, label')
          .eq('is_active', true),
    ]);

    final positions = (responses[0] as List<dynamic>)
        .map((json) => MasterOption.fromJson(json as Map<String, dynamic>))
        .toList();
    final divisions = (responses[1] as List<dynamic>)
        .map((json) => MasterOption.fromJson(json as Map<String, dynamic>))
        .toList();

    return (
      {
        for (final item in positions) item.code: item.label,
      },
      {
        for (final item in divisions) item.code: item.label,
      },
    );
  }

  bool _isMissingView(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' || message.contains('v_member_workload');
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  String _buildWorkloadStatus({
    required int weeklyCapacityHours,
    required double loadRatio,
  }) {
    if (weeklyCapacityHours == 0) {
      return 'no_capacity';
    }

    if (loadRatio > 1) {
      return 'overload';
    }

    if (loadRatio >= 0.8) {
      return 'warning';
    }

    return 'safe';
  }
}
