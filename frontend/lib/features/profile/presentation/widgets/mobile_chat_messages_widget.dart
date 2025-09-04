// Deprecated: unified into ChatMessagesWidget. Thin wrapper kept for compatibility.
import 'package:flutter/widgets.dart';
import 'chat_messages_widget.dart';

class MobileChatMessagesWidget extends StatelessWidget {
  const MobileChatMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) => const ChatMessagesWidget();
}