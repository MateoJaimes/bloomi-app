import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_ui.dart';
import '../../../core/widgets/bloomi_design.dart';
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
  void initState() {
    super.initState();
    _answers.addAll(widget.repository.answers ?? {});
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.repository.questions;
    return BloomiFormLayout(
      title: 'Cuestionario de salud',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: questions.isEmpty
                ? 0
                : (_answers.length / questions.length).clamp(0, 1),
            minHeight: 10,
            color: AppColors.lavenderInk,
            backgroundColor: AppColors.lavender,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Cuéntanos cómo te sientes',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Responde con sinceridad. El personal médico del centro revisará tus respuestas.',
          style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 22),
        if (questions.isEmpty)
          BloomiSurface(
            child: Column(
              children: [
                const BloomiEmblem(Icons.assignment_outlined, size: 60),
                const SizedBox(height: 12),
                Text(
                  widget.repository.loadError == null
                      ? 'No hay un cuestionario activo por ahora.'
                      : 'No pudimos cargar el cuestionario. Intenta de nuevo.',
                  textAlign: TextAlign.center,
                ),
                if (widget.repository.loadError != null)
                  TextButton(
                    onPressed: _refreshing ? null : _retryLoad,
                    child: const Text('Reintentar'),
                  ),
              ],
            ),
          )
        else
          for (var index = 0; index < questions.length; index++) ...[
            BloomiSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BloomiEmblem(
                        Icons.fact_check_outlined,
                        size: 40,
                        background: [
                          AppColors.mint,
                          AppColors.peach,
                          AppColors.lavender,
                        ][index % 3],
                        foreground: [
                          AppColors.mintInk,
                          AppColors.primaryDark,
                          AppColors.lavenderInk,
                        ][index % 3],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          questions[index].prompt,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: true, label: Text('Sí')),
                        ButtonSegment(value: false, label: Text('No')),
                      ],
                      selected: _answers.containsKey(questions[index].id)
                          ? {_answers[questions[index].id]!}
                          : {},
                      onSelectionChanged: (selection) => setState(() {
                        if (selection.isEmpty) {
                          _answers.remove(questions[index].id);
                        } else {
                          _answers[questions[index].id] = selection.first;
                        }
                      }),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.primary
                              : AppColors.surface,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : AppColors.ink,
                        ),
                        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: questions.isEmpty ? null : _submit,
          child: Text(
            'Guardar respuestas (${_answers.length}/${questions.length})',
          ),
        ),
      ],
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
    if (!questions
        .where((question) => question.required)
        .every((question) => _answers.containsKey(question.id))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa todas las preguntas obligatorias.')),
      );
      return;
    }
    try {
      await widget.repository.submitAnswers(_answers);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
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
