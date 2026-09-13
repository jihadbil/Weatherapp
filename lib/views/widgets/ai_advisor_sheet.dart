import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/ai_weather_service.dart';
import '../../theme/weather_colors.dart';

class AIAdvisorSheet extends StatefulWidget {
  final FullWeatherData weather;
  final LocationData location;
  final VoidCallback? onAppNeedsRefresh;

  const AIAdvisorSheet({
    super.key,
    required this.weather,
    required this.location,
    this.onAppNeedsRefresh,
  });

  static void show(
    BuildContext context, {
    required FullWeatherData weather,
    required LocationData location,
    VoidCallback? onAppNeedsRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIAdvisorSheet(
        weather: weather,
        location: location,
        onAppNeedsRefresh: onAppNeedsRefresh,
      ),
    );
  }

  @override
  State<AIAdvisorSheet> createState() => _AIAdvisorSheetState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<AIActionStatus> actionStatuses;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.actionStatuses = const [],
  });
}

class _AIAdvisorSheetState extends State<AIAdvisorSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    '➕ أضف طوكيو إلى قائمتي المفضلة',
    '🗺️ افتح خريطة رادار الطقس',
    '⚖️ قارن بين القاهرة والرياض',
    '🌡️ حول وحدة درجات الحرارة إلى فهرنهايت',
    '🚗 هل الجو مناسب لغسيل السيارة اليوم؟',
    '🥩 هل يناسب الطقس الشواء وجلسة السمر الليلة؟',
    '🚴 هل الطقس ملائم للجري وركوب الدراجة؟',
    '🧺 هل يمكن نشر الغسيل في الشرفة الآن؟',
    '🕌 أظهر مواقيت الصلاة في التطبيق',
  ];

  @override
  void initState() {
    super.initState();
    // Initial welcome message highlighting autonomous abilities
    _messages.add(
      _ChatMessage(
        text: 'أهلاً بك! أنا وكيلك الذكي للطقس في ${widget.location.name} 🤖✨\n\nاسألني عن أي نشاط تخطط له وسأحلل الرياح والأمطار والحرارة، أو اطلب مني التحكم في إعدادات التطبيق مباشرة (مثل: "أضف دبي للمفضلة"، "حول لفهرنهايت"، أو "افتح الرادار")!',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
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
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final result = await AIWeatherService.askAdvisor(
        question: query,
        weather: widget.weather,
        location: widget.location,
      );

      if (!mounted) return;

      final List<AIActionStatus> statuses = [];
      for (final action in result.actions) {
        if (!mounted) break;
        final status = await AIWeatherService.executeAction(
          context,
          action,
          currentLocation: widget.location,
        );
        statuses.add(status);
      }

      if (statuses.any((s) => s.success && s.modifiesSettings)) {
        widget.onAppNeedsRefresh?.call();
      }

      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: result.text,
              isUser: false,
              time: DateTime.now(),
              actionStatuses: statuses,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        final fallbackResult = AIWeatherService.ruleBasedAdvisor(
          question: query,
          weather: widget.weather,
          location: widget.location,
        );

        final List<AIActionStatus> statuses = [];
        for (final action in fallbackResult.actions) {
          if (!mounted) break;
          final status = await AIWeatherService.executeAction(
            context,
            action,
            currentLocation: widget.location,
          );
          statuses.add(status);
        }

        if (statuses.any((s) => s.success && s.modifiesSettings)) {
          widget.onAppNeedsRefresh?.call();
        }

        setState(() {
          _messages.add(_ChatMessage(
            text: fallbackResult.text,
            isUser: false,
            time: DateTime.now(),
            actionStatuses: statuses,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Colors.amberAccent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0F172A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'وكيل ومساعد الطقس الذكي (AI Agent)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تحكم واستشارة ذكية • Gemini 3.6 Flash • ${widget.location.name}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 16),

          // Quick Prompt Chips Carousel
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, i) {
                final prompt = _quickPrompts[i];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ActionChip(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    label: Text(
                      prompt,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    onPressed: _isLoading ? null : () => _sendMessage(prompt),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'جاري المعالجة وتنفيذ الأوامر بالذكاء الاصطناعي... 🧠⚡',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 11),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'اسأل عن الطقس أو اطلب أمراً (مثال: أضف روما للمفضلة)...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _sendMessage(val),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_textController.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF38BDF8), Colors.amberAccent],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF0F172A), size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 28),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ),
      );
    } else {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, left: 16),
          padding: const EdgeInsets.all(14),
          decoration: WeatherColors.glassDecoration(borderRadius: 18, opacity: 0.12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                    if (msg.actionStatuses.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...msg.actionStatuses.map(
                        (status) => Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: status.success
                                ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                : const Color(0xFFEF4444).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: status.success
                                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: status.success
                                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  status.icon,
                                  color: status.success ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  status.description,
                                  style: TextStyle(
                                    color: status.success ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status.success
                                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.success ? 'تم بنجاح' : 'تنبيه',
                                  style: TextStyle(
                                    color: status.success ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
