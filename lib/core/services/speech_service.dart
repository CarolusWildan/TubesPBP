import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  String? _lastWords;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String message)? onError,
  }) async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError?.call(error.errorMsg),
    );

    return _isInitialized;
  }

  Future<void> startSearchListening({
    required void Function(String words, bool isFinal) onResult,
    void Function(String message)? onError,
  }) async {
    final ready = await initialize(onError: onError);
    if (!ready) {
      onError?.call('Voice search belum tersedia atau izin mikrofon ditolak.');
      return;
    }

    _lastWords = null;
    final localeId = await _preferredLocaleId();

    await _speech.listen(
      localeId: localeId,
      listenMode: ListenMode.search,
      partialResults: true,
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty || words == _lastWords) return;

        _lastWords = words;
        onResult(words, result.finalResult);
      },
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();

  Future<String?> _preferredLocaleId() async {
    final locales = await _speech.locales();
    final deviceLocale = await _speech.systemLocale();

    final localeIds = [
      'id_ID',
      deviceLocale?.localeId,
      if (locales.isNotEmpty) locales.first.localeId,
    ];

    for (final localeId in localeIds) {
      if (localeId == null) continue;
      if (locales.any((locale) => locale.localeId == localeId)) {
        return localeId;
      }
    }

    return null;
  }
}
