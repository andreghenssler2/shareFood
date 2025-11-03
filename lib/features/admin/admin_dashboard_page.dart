import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_users_page.dart';
import 'admin_ongs_page.dart';
import 'admin_parceiros_page.dart';
import 'admin_doacoes_pedidos_page.dart';
import 'admin_reports_page.dart';
import 'admin_profile_page.dart';
import '../auth/pages/login_page.dart'; 


class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel do Administrador',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () async {
              final sair = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar saída'),
                  content: const Text('Deseja realmente sair da conta?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text('Sair'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (sair == true) {
                _logout(context);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: StreamZip<QuerySnapshot>([
          firestore.collection('users').snapshots(),
          firestore.collection('ongs').snapshots(),
          firestore.collection('parceiros').snapshots(),
          firestore.collection('doacoes').snapshots(),
          firestore.collection('pedidos').snapshots(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Sem dados disponíveis."));
          }

          final data = snapshot.data!;
          final usersCount = data[0].docs.length;
          final ongsCount = data[1].docs.length;
          final partnersCount = data[2].docs.length;

          final doacoesDocs = data[3].docs;
          final activeDoacoes =
              doacoesDocs.where((d) => (d.data() as Map<String, dynamic>)['ativo'] == true).length;
          final totalDoacoes = doacoesDocs.length;

          final pedidosDocs = data[4].docs;
          final pedidosPendentes = pedidosDocs
              .where((p) => ((p.data() as Map<String, dynamic>)['status'] ?? '')
                  .toString()
                  .toLowerCase() ==
                  'pendente')
              .length;
          final totalPedidos = pedidosDocs.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visão Geral',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 📊 Cards de resumo
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossCount = constraints.maxWidth > 800
                        ? 4
                        : constraints.maxWidth > 500
                            ? 3
                            : 2;
                    return GridView.count(
                      crossAxisCount: crossCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildSummaryCard(
                          title: 'Usuários',
                          value: usersCount.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        _buildSummaryCard(
                          title: 'ONGs',
                          value: ongsCount.toString(),
                          icon: Icons.handshake,
                          color: Colors.orange,
                        ),
                        _buildSummaryCard(
                          title: 'Parceiros',
                          value: partnersCount.toString(),
                          icon: Icons.store,
                          color: Colors.green,
                        ),
                        _buildSummaryCard(
                          title: 'Doações Ativas',
                          value: activeDoacoes.toString(),
                          icon: Icons.volunteer_activism,
                          color: Colors.purple,
                        ),
                        _buildSummaryCard(
                          title: 'Total de Doações',
                          value: totalDoacoes.toString(),
                          icon: Icons.card_giftcard,
                          color: Colors.indigo,
                        ),
                        _buildSummaryCard(
                          title: 'Pedidos Pendentes',
                          value: pedidosPendentes.toString(),
                          icon: Icons.pending_actions,
                          color: Colors.redAccent,
                        ),
                        _buildSummaryCard(
                          title: 'Total de Pedidos',
                          value: totalPedidos.toString(),
                          icon: Icons.receipt_long,
                          color: Colors.teal,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),
                const Text(
                  'Ações Administrativas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildActionButton(
                  icon: Icons.manage_accounts,
                  label: 'Gerenciar Usuários',
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminUsersPage()),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.handshake_outlined,
                  label: 'Gerenciar ONGs',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminOngsPage()),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.store_mall_directory_outlined,
                  label: 'Gerenciar Parceiros',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminParceirosPage()),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Doações e Pedidos',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDoacoesPedidosPage()),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.insert_chart_outlined,
                  label: 'Relatórios e Estatísticas',
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminReportsPage()),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.person_outline,
                  label: 'Meu Perfil',
                  color: Colors.redAccent,
                  onTap: () {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminPerfilPage(uid: uid)),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
