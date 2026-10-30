import '../../../core/network/api_client.dart';
import '../domain/health_question.dart';
import 'sample_health_questions.dart';

abstract interface class HealthQuestionnaireRepository {
  Map<String, bool>? get answers;
  List<HealthQuestion> get questions;
  String? get loadError;
  Future<void> load();
  Future<void> submitAnswers(Map<String, bool> answers);
}

/// Temporary volatile response store. Submitted health data never leaves memory.
class SessionHealthQuestionnaireRepository
    implements HealthQuestionnaireRepository {
  Map<String, bool>? _answers;

  @override
  List<HealthQuestion> get questions => sampleHealthQuestions;

  @override
  String? get loadError => null;

  @override
  Future<void> load() async {}

  @override
  Map<String, bool>? get answers =>
      _answers == null ? null : Map.unmodifiable(_answers!);

  @override
  Future<void> submitAnswers(Map<String, bool> answers) async {
    _answers = Map.unmodifiable(answers);
  }
}

class ApiHealthQuestionnaireRepository implements HealthQuestionnaireRepository {
  ApiHealthQuestionnaireRepository(this.api);
  final ApiClient api;
  String? _versionId;
  List<HealthQuestion> _questions = [];
  Map<String, bool>? _answers;
  String? _loadError;

  @override
  List<HealthQuestion> get questions => List.unmodifiable(_questions);
  @override
  Map<String, bool>? get answers => _answers == null ? null : Map.unmodifiable(_answers!);
  @override
  String? get loadError => _loadError;

  @override
  Future<void> load() async {
    _loadError = null;
    try {
      final result = await api.get('/me/questionnaire') as Map<String, dynamic>;
      _answers = result['latestSubmission'] is Map<String, dynamic> ? <String, bool>{} : null;
      final active = result['active'];
      if (active is! Map<String, dynamic>) { _questions = []; return; }
      _versionId = active['id'] as String?;
      _questions = (active['questions'] as List).map((raw) {
        final row = raw as Map<String, dynamic>;
        return HealthQuestion(id: row['id'].toString(), category: row['category'] as String? ?? 'General', prompt: row['prompt'] as String? ?? '', required: row['required'] as bool? ?? true);
      }).toList();
    } catch (error) {
      _loadError = error.toString();
      rethrow;
    }
  }

  @override
  Future<void> submitAnswers(Map<String, bool> answers) async {
    final version = _versionId;
    if (version == null) throw const ApiException('No hay un cuestionario activo en este momento.');
    await api.post('/me/questionnaire', body: {'versionId': version, 'answers': answers.entries.map((entry) => {'questionId': entry.key, 'answer': entry.value}).toList()});
    _answers = Map.unmodifiable(answers);
  }
}
