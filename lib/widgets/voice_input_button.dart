import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/app_colors.dart';

class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;
  final String locale; // 'en_IN' or 'hi_IN'

  const VoiceInputButton({
    super.key,
    required this.controller,
    this.locale = 'en_IN',
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) return;

    setState(() => _isListening = true);
    await _speech.listen(
      localeId: widget.locale,
      onResult: (result) {
        widget.controller.text = result.recognizedWords;
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isListening
              ? AppColors.statusError.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening ? AppColors.statusError : AppColors.textTertiary,
          size: 22,
        ),
      ),
    );
  }
}
