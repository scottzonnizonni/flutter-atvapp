import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../utils/constants.dart';
import '../widgets/journey_card.dart';
import '../widgets/path_painter.dart';
import 'content_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;

  @override
  void initState() {
    super.initState();
    _pathAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pathAnimation = CurvedAnimation(
      parent: _pathAnimationController,
      curve: Curves.easeInOut,
    );
    _pathAnimationController.forward();

    // Load history when screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _pathAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundBlack),
      appBar: AppBar(
        title: const Text('Meu Percurso'),
        backgroundColor: const Color(AppConstants.primaryGreen),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, historyProvider, _) {
              if (historyProvider.history.isEmpty) return const SizedBox();

              return IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'Reiniciar Percurso',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(AppConstants.cardDark),
                      title: const Text(
                        'Reiniciar Percurso',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Deseja apagar os registros da sua caminhada pelo território?',
                        style: TextStyle(color: Color(AppConstants.textGray)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(
                              AppConstants.deleteRed,
                            ),
                          ),
                          child: const Text('Reiniciar'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await context.read<HistoryProvider>().clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Percurso reiniciado'),
                          backgroundColor: Color(AppConstants.primaryGreen),
                        ),
                      );
                      // Reiniciar animação
                      _pathAnimationController.reset();
                      _pathAnimationController.forward();
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, _) {
          if (historyProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(AppConstants.primaryGreen),
              ),
            );
          }

          // Show error state
          if (historyProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Erro ao carregar histórico',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      historyProvider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(AppConstants.textGray),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        historyProvider.loadHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.primaryGreen),
                      ),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (historyProvider.history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 100,
                      color: const Color(
                        AppConstants.primaryGreen,
                      ).withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sua jornada pelo território\nainda não começou',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Explore Terra Vista e descubra\nseus pontos de memória',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(AppConstants.textGray),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          AppConstants.primaryGreen,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            AppConstants.primaryGreen,
                          ).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: const Color(AppConstants.primaryGreen),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Escaneie um QR Code para começar',
                            style: TextStyle(
                              color: const Color(AppConstants.primaryGreen),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await historyProvider.loadHistory();
              _pathAnimationController.reset();
              _pathAnimationController.forward();
            },
            color: const Color(AppConstants.primaryGreen),
            child: _buildJourneyPath(historyProvider),
          );
        },
      ),
    );
  }

  Widget _buildJourneyPath(HistoryProvider historyProvider) {
    final itemCount = historyProvider.history.length;
    const itemHeight = 280.0; // Altura aproximada de cada card + espaçamento
    final totalHeight = itemCount * itemHeight + 100;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Linha serpenteante de fundo
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pathAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: PathPainter(
                      itemCount: itemCount,
                      itemHeight: itemHeight,
                      animationValue: _pathAnimation.value,
                    ),
                  );
                },
              ),
            ),

            // Header com contador
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      AppConstants.primaryGreen,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: const Color(AppConstants.primaryGreen),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$itemCount ${itemCount == 1 ? 'ponto visitado' : 'pontos visitados'}',
                        style: TextStyle(
                          color: const Color(AppConstants.primaryGreen),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Cards alternados
            ...List.generate(itemCount, (index) {
              final scan = historyProvider.history[index];
              final content = historyProvider.contentCache[scan.contentId];

              if (content == null) return const SizedBox();

              final isLeft = index % 2 == 0;
              final yPosition = 60.0 + (index * itemHeight);

              return Positioned(
                top: yPosition,
                left: isLeft ? 16 : null,
                right: isLeft ? null : 16,
                width: MediaQuery.of(context).size.width * 0.7,
                child: JourneyCard(
                  content: content,
                  visitedAt: scan.scannedAt,
                  isLeft: isLeft,
                  index: index,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ContentDetailScreen(content: content),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
