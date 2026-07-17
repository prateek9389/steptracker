import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shimmer_loader.dart';
import '../../providers/ai_coach_provider.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) {
    final msg = text ?? _msgController.text;
    if (msg.trim().isEmpty) return;

    ref.read(aiCoachProvider.notifier).sendMessage(msg);
    _msgController.clear();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(aiCoachProvider, (previous, next) {
      if (previous == null ||
          next.messages.length != previous.messages.length ||
          next.isTyping != previous.isTyping) {
        _scrollToBottom();
      }
    });

    final coachState = ref.watch(aiCoachProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header drawer grabber
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'StrideAI Coach',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Online', style: TextStyle(fontSize: 10, color: AppColors.textMutedDark, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMutedDark),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Chat Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: coachState.messages.length,
              itemBuilder: (context, idx) {
                final msg = coachState.messages[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: msg.isUser
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark ? Colors.white : AppColors.textLight),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Typing Loader Indicator
          if (coachState.isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  ShimmerLoader(width: 60, height: 28, borderRadius: 12),
                  SizedBox(width: 8),
                  Text('Typing...', style: TextStyle(fontSize: 10, color: AppColors.textMutedDark, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Suggested Chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: coachState.suggestions.length,
              itemBuilder: (context, idx) {
                final suggestion = coachState.suggestions[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: ActionChip(
                    label: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                      ),
                    ),
                    backgroundColor: isDark ? const Color(0xFF131C2E) : const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                    ),
                    onPressed: () => _sendMessage(suggestion),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Message Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Voice input recording started...'), backgroundColor: AppColors.primary, duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ),
                    onSubmitted: (val) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.black),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
