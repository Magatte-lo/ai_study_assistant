import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String? sessionId;

  const ChatPage({super.key, this.sessionId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  String? _sessionId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    if (_sessionId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final id =
        await ref.read(chatControllerProvider.notifier).createSession();
        if (mounted) setState(() => _sessionId = id);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    final messages =
        ref.read(chatMessagesProvider(sessionId)).valueOrNull ?? [];

    await ref.read(chatControllerProvider.notifier).sendMessage(
      sessionId: sessionId,
      userMessage: text,
      currentMessages: messages,
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final isLoading = chatState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat IA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _sessionId == null
          ? const Center(child: CircularProgressIndicator())
          : _buildChatBody(_sessionId!, isLoading),
    );
  }

  Widget _buildChatBody(String sessionId, bool isLoading) {
    final messagesAsync = ref.watch(chatMessagesProvider(sessionId));

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur: $err')),
            data: (messages) {
              if (messages.isEmpty && !isLoading) {
                return _buildEmptyState();
              }
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return const TypingIndicator();
                  }
                  return MessageBubble(message: messages[index]);
                },
              );
            },
          ),
        ),
        ChatInput(
          onSend: _sendMessage,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Pose-moi une question !',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Je suis ton assistant IA pour t\'aider dans tes études.\nMaths, langues, sciences, philosophie...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}