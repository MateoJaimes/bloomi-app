import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_ui.dart';
import '../../../core/widgets/bloomi_design.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.onFindCenters,
    required this.onShowRewards,
    super.key,
  });
  final VoidCallback onFindCenters;
  final VoidCallback onShowRewards;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<({String question, String answer})> _messages = [];
  static const _topics = [
    (
      question: '¿Dónde encuentro centros?',
      answer: 'En Centros puedes buscar por ciudad o institución y consultar su dirección. Confirma los horarios directamente con el centro.',
    ),
    (
      question: '¿Cómo uso mis puntos?',
      answer: 'En Canjes verás tu saldo y las recompensas disponibles. Elige una y confirma el canje. Si te faltan puntos, verás cuántos necesitas.',
    ),
    (
      question: '¿Dónde actualizo mis datos?',
      answer: 'En Inicio, toca el perfil de la esquina superior izquierda para editar tus datos personales. El resumen médico y el cuestionario se encuentran en esa misma pantalla.',
    ),
  ];
  @override
  Widget build(BuildContext context) => BloomiPage(
    quietHeader: true,
    children: [
      const BloomiTitle(
        'Asistente Bloomi',
        'Ayuda guiada para moverte por tu cuenta.',
      ),
      const SizedBox(height: 24),
      const Center(
        child: BloomiEmblem(
          Icons.smart_toy_outlined,
          size: 90,
          background: AppColors.mint,
          foreground: AppColors.mintInk,
        ),
      ),
      const SizedBox(height: 14),
      const Center(
        child: BloomiPill(
          'Ayuda guiada',
          color: AppColors.mint,
          foreground: AppColors.mintInk,
        ),
      ),
      const SizedBox(height: 20),
      const BloomiNotice(
        title: '¿En qué te puedo ayudar?',
        detail: 'Elige un tema para consultar cómo funciona Bloomi.',
        icon: 'assignment-outline-rounded',
      ),
      const SizedBox(height: 20),
      for (final message in _messages) ...[
        Align(
          alignment: Alignment.centerRight,
          child: BloomiSurface(
            color: AppColors.blush,
            child: Text(
              message.question,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        BloomiSurface(
          child: Text(
            message.answer,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
      ],
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final topic in _topics)
            ActionChip(
              label: Text(topic.question),
              onPressed: () => setState(() => _messages.add(topic)),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton(
            onPressed: widget.onFindCenters,
            child: const Text('Buscar centros'),
          ),
          OutlinedButton(
            onPressed: widget.onShowRewards,
            child: const Text('Ver mis canjes'),
          ),
        ],
      ),
    ],
  );
}
