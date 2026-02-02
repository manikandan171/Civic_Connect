import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart';  // Temporarily disabled
import '../constants/app_theme.dart';

class VoiceSettingsWidget extends StatefulWidget {
  final bool voiceInputEnabled;
  final Function(bool) onVoiceInputChanged;

  const VoiceSettingsWidget({
    super.key,
    required this.voiceInputEnabled,
    required this.onVoiceInputChanged,
  });

  @override
  State<VoiceSettingsWidget> createState() => _VoiceSettingsWidgetState();
}

class _VoiceSettingsWidgetState extends State<VoiceSettingsWidget> {
  // final SpeechToText _speechToText = SpeechToText();  // Temporarily disabled
  final bool _isListening = false;
  final bool _speechAvailable =
      false; // Set to false since speech_to_text is disabled
  String _recognizedText = '';
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    // _initSpeech();  // Temporarily disabled
  }

  // Future<void> _initSpeech() async {  // Temporarily disabled
  //   _speechAvailable = await _speechToText.initialize(
  //     onError: (error) {
  //       setState(() {
  //         _lastError = error.errorMsg;
  //       });
  //     },
  //     onStatus: (status) {
  //       setState(() {
  //         _isListening = status == 'listening';
  //       });
  //     },
  //   );
  //   setState(() {});
  // }

  Future<void> _startListening() async {
    // Temporarily disabled - speech_to_text plugin removed
    setState(() {
      _lastError = 'Voice input is temporarily disabled due to build issues.';
    });
  }

  Future<void> _stopListening() async {
    // Temporarily disabled - speech_to_text plugin removed
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Input Toggle
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Input',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Use voice to report issues and describe problems',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Switch(
              value: widget.voiceInputEnabled,
              onChanged: widget.onVoiceInputChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),

        if (widget.voiceInputEnabled) ...[
          const SizedBox(height: 16),

          // Speech Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _speechAvailable
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _speechAvailable
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _speechAvailable ? Icons.mic : Icons.mic_off,
                  color: _speechAvailable ? AppColors.success : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _speechAvailable
                        ? 'Voice recognition is available'
                        : 'Voice recognition is not available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _speechAvailable
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Test Voice Input
          if (_speechAvailable) ...[
            Text(
              'Test Voice Input',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Voice Input Test Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Recognized Text Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _recognizedText.isEmpty
                          ? 'Tap the microphone and speak...'
                          : _recognizedText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _recognizedText.isEmpty
                            ? Colors.grey[500]
                            : Colors.black87,
                        fontStyle: _recognizedText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Voice Control Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isListening
                              ? _stopListening
                              : _startListening,
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isListening ? 'Stop Listening' : 'Start Listening',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening
                                ? AppColors.error
                                : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _recognizedText = '';
                            _lastError = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_lastError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastError,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Voice Input Tips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice Input Tips',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Speak clearly and at a moderate pace\n'
                  '• Describe the issue in detail\n'
                  '• Mention the location if possible\n'
                  '• Use simple, clear language',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
