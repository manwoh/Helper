import '../core/supabase_client.dart';
import '../models/message.dart';

class ChatService {
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => ChatMessage.fromMap(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    final user = supabase.auth.currentUser!;
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'message_type': 'text',
      'body': body.trim(),
    });
  }

  Future<String?> findConversationForTask(String taskId) async {
    final user = supabase.auth.currentUser!;
    final row = await supabase
        .from('conversations')
        .select('id')
        .eq('task_id', taskId)
        .or('requester_id.eq.${user.id},helper_id.eq.${user.id}')
        .maybeSingle();

    return row == null ? null : row['id'] as String;
  }
}
