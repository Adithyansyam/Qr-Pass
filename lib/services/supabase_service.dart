import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onam_pass/models/student.dart';
import 'package:onam_pass/utils/constants.dart';

/// Result returned by [SupabaseService.approvePass].
enum ApprovalResult {
  success,
  alreadyApproved,
  notFound,
  error,
}

/// All Supabase database operations for the Onam Pass app.
class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // -------------------------------------------------------------------------
  // Generate Pass
  // -------------------------------------------------------------------------

  /// Insert a new student pass record.
  /// Returns the inserted [Student] on success.
  static Future<Student> generatePass(Student student) async {
    final data = await _client
        .from(DbTable.students)
        .insert(student.toInsertMap())
        .select()
        .single();
    return Student.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Fetch Pass
  // -------------------------------------------------------------------------

  /// Fetch a student by pass ID.
  /// Returns null if no record exists (invalid QR).
  static Future<Student?> fetchPass(String passId) async {
    final data = await _client
        .from(DbTable.students)
        .select()
        .eq('pass_id', passId)
        .maybeSingle();

    if (data == null) return null;
    return Student.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Approve Pass (atomic server-side RPC)
  // -------------------------------------------------------------------------

  /// Approve a pass atomically using a PostgreSQL RPC function.
  ///
  /// The server function `approve_pass` will:
  ///   1. Find the row by pass_id
  ///   2. Check status == 'pending'
  ///   3. Update status, approved_at, approved_by atomically
  ///   4. Return result: 'approved' | 'already_approved' | 'not_found'
  ///
  /// This prevents race conditions when two scanners scan simultaneously.
  static Future<ApprovalResult> approvePass({
    required String passId,
    required String staffUserId,
  }) async {
    try {
      final result = await _client.rpc(
        'approve_pass',
        params: {
          'p_pass_id': passId,
          'p_approved_by': staffUserId,
        },
      );

      switch (result as String) {
        case 'approved':
          return ApprovalResult.success;
        case 'already_approved':
          return ApprovalResult.alreadyApproved;
        case 'not_found':
          return ApprovalResult.notFound;
        default:
          return ApprovalResult.error;
      }
    } on PostgrestException catch (e) {
      // RLS denial or other DB error
      if (e.code == 'PGRST301' || e.message.contains('permission')) {
        rethrow; // let callers handle auth errors distinctly
      }
      return ApprovalResult.error;
    }
  }

  // -------------------------------------------------------------------------
  // Statistics
  // -------------------------------------------------------------------------

  /// Returns a map with keys: total, pending, approved.
  static Future<Map<String, int>> getStatistics() async {
    // Fetch all statuses in a single lightweight query.
    final data = await _client
        .from(DbTable.students)
        .select('status');

    int total = 0, pending = 0, approved = 0;
    for (final row in data as List) {
      total++;
      if (row['status'] == PassStatus.pending) pending++;
      if (row['status'] == PassStatus.approved) approved++;
    }
    return {'total': total, 'pending': pending, 'approved': approved};
  }

  /// Real-time stream of statistics.
  /// Emits a new value whenever the students table changes.
  static Stream<Map<String, int>> statisticsStream() async* {
    // Initial fetch
    yield await getStatistics();

    // Listen to Realtime changes and re-fetch stats
    yield* _client
        .from(DbTable.students)
        .stream(primaryKey: ['id'])
        .map((rows) {
          int total = rows.length;
          int pending = rows.where((r) => r['status'] == PassStatus.pending).length;
          int approved = rows.where((r) => r['status'] == PassStatus.approved).length;
          return {'total': total, 'pending': pending, 'approved': approved};
        });
  }

  // -------------------------------------------------------------------------
  // Student Search
  // -------------------------------------------------------------------------

  /// Search students by name, pass ID, class, or roll number.
  static Future<List<Student>> searchStudents(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim();

    // Try pass ID match first (exact prefix match)
    if (q.toUpperCase().startsWith('ONAM-')) {
      final data = await _client
          .from(DbTable.students)
          .select()
          .ilike('pass_id', '%$q%')
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List).map((r) => Student.fromMap(r)).toList();
    }

    // Full-text search on name and roll_number
    final data = await _client
        .from(DbTable.students)
        .select()
        .or('name.ilike.%$q%,class_name.ilike.%$q%,roll_number.ilike.%$q%')
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List).map((r) => Student.fromMap(r)).toList();
  }
}
