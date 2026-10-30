import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/health_questionnaire_repository.dart';

class HealthQuestionnaireScreen extends StatefulWidget {
  const HealthQuestionnaireScreen({required this.repository, super.key});

  final HealthQuestionnaireRepository repository;

  @override
  State<HealthQuestionnaireScreen> createState() =>
      _HealthQuestionnaireScreenState();
}

class _HealthQuestionnaireScreenState extends State<HealthQuestionnaireScreen> {
  final Map<String, bool> _answers = {};
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.repository.questions;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuestionario de salud')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Responde con sinceridad. El equipo de salud del centro revisará esta información y decidirá si puedes donar.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
            Expanded(
              child: questions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.repository.loadError == null ? Icons.assignment_outlined : Icons.cloud_off_rounded, color: AppColors.primary, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              widget.repository.loadError == null
                                  ? 'No hay un cuestionario activo por ahora.'
                                  : 'No pudimos cargar el cuestionario. ${widget.repository.loadError}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.muted, height: 1.4),
                            ),
                            if (widget.repository.loadError != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _refreshing ? null : _retryLoad,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final previousCategory = index == 0
                      ? null
                      : questions[index - 1].category;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (question.category != previousCategory)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                          child: Text(
                            question.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.prompt,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                              RadioGroup<bool>(
                                groupValue: _answers[question.id],
                                onChanged: (answer) {
                                  if (answer != null) {
                                    setState(
                                      () => _answers[question.id] = answer,
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: RadioListTile<bool>(
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        title: Text('Sí'),
                                        value: true,
                                      ),
                                    ),
                                    const Expanded(
                                      child: RadioListTile<bool>(
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        title: Text('No'),
                                        value: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: questions.isEmpty ? null : _submit,
                  child: Text(
                    'Guardar respuestas (${_answers.length}/${questions.length})',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryLoad() async {
    setState(() => _refreshing = true);
    try {
      await widget.repository.load();
    } catch (_) {
      // The repository exposes the error so the empty state can show it.
    }
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _submit() async {
    final questions = widget.repository.questions;
    if (!questions.where((question) => question.required).every((question) => _answers.containsKey(question.id))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completa todas las preguntas obligatorias.',
          ),
        ),
      );
      return;
    }
    try {
      await widget.repository.submitAnswers(_answers);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Respuestas guardadas. El personal médico debe evaluar tu elegibilidad.',
        ),
      ),
    );
  }
}
