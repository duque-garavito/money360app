import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/providers/data_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../accounts/presentation/accounts_tab.dart'; 
import '../../categories/presentation/categories_tab.dart'; 
import '../../transactions/presentation/transactions_tab.dart';
import '../../settings/presentation/settings_screen.dart';

// Import New Chart Widgets
import 'widgets/expenses_pie_chart.dart';
import 'widgets/cashflow_bar_chart.dart';
import 'widgets/balance_trend_bar_chart.dart';

class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(() {
  return BottomNavIndexNotifier();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      const _DashboardHomeTab(),
      const AccountsTab(), 
      const TransactionsTab(), // Usar Tab de Transacciones
      const CategoriesTab(),
    ];

    return Scaffold(
      extendBody: true, // Deja que el contenido pase por debajo del bottom bar flotante
      backgroundColor: isDark ? const Color(0xFF101418) : const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Money360', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          )
        ],
      ),
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(bottomNavIndexProvider.notifier).setIndex(index);
              },
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.greenAccent.withOpacity(0.3),
              elevation: 0,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded, color: Colors.greenAccent),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.greenAccent),
                  label: 'Cuentas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_horizontal_circle_outlined),
                  selectedIcon: Icon(Icons.swap_horizontal_circle_rounded, color: Colors.greenAccent),
                  label: 'Transacciones',
                ),
                NavigationDestination(
                  icon: Icon(Icons.label_outline_rounded),
                  selectedIcon: Icon(Icons.label_rounded, color: Colors.greenAccent),
                  label: 'Etiquetas',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------ TAB 0: EL DASHBOARD PRINCIPAL ------
class _DashboardHomeTab extends ConsumerWidget {
  const _DashboardHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final authState = ref.watch(authStateProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final accounts = accountsAsync.value ?? [];
    final transactions = transactionsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(bottom: 120), // Bottom padding for nav bar
        children: [
          // Greeting
          Text(
            'Hola, ${authState.value?.displayName != null && authState.value!.displayName!.isNotEmpty ? authState.value!.displayName : (authState.value?.email?.split('@').first ?? 'Usuario')}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),

          // Glassmorphic Master Card
          _buildMasterBalanceCard(context, totalBalance, isDark),
          const SizedBox(height: 24),

          // Ingresos y Gastos
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  title: 'Ingresos',
                  amount: monthlySummary['income'] ?? 0,
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.greenAccent[400]!,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  title: 'Gastos',
                  amount: monthlySummary['expense'] ?? 0,
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.redAccent[400]!,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Tus Cuentas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Gráfico de anillo
          _GlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Distribución de Cuentas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (accounts.isNotEmpty && totalBalance > 0)
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: accounts.map((acc) {
                          final color = Color(int.parse(acc.color.replaceFirst('#', '0xff')));
                          return PieChartSectionData(
                            color: color,
                            value: acc.balance.abs() > 0 ? acc.balance.abs() : 1, // ensure it shows a sliver
                            title: CurrencyFormatter.format(acc.balance),
                            radius: 40,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          _GlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flujo de Fondos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CashflowBarChart(transactions: transactions),
              ],
            )
          ),

          const SizedBox(height: 32),
          _GlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tendencia de Variación Diaria', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                BalanceTrendBarChart(transactions: transactions),
              ]
            ),
          ),

          const SizedBox(height: 32),
          _GlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gastos Acumulados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ExpensesPieChart(transactions: transactions, categories: categories),
              ]
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMasterBalanceCard(BuildContext context, double totalBalance, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
            : [const Color(0xFF38EF7D), const Color(0xFF11998E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF1E3C72) : const Color(0xFF11998E)).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Graphic overlay
          Positioned(
            right: -30,
            top: -30,
            child: Icon(Icons.account_balance_wallet_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(totalBalance),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 36,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(BuildContext context, {required String title, required double amount, required IconData icon, required Color color, required bool isDark}) {
    return _GlassContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// ------ TABS TEMPORALES ------
class _ComingSoonTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '$title\nPróximamente',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

// ------ UTILIDAD ------
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({
    required this.child,
    required this.isDark,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
