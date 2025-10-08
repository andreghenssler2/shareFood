import 'package:flutter/material.dart';
import 'package:sharefood/features/donations/services/donation_service.dart';
import 'package:sharefood/features/donations/models/donation_model.dart';

class MyDonationsPage extends StatelessWidget {
  const MyDonationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final donationService = DonationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Doações')),
      body: StreamBuilder<List<Donation>>(
        stream: donationService.getUserDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Você ainda não cadastrou doações.'),
            );
          }

          final donations = snapshot.data!;
          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final d = donations[index];
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.fastfood,
                    color: Colors.green,
                    size: 40,
                  ),
                  title: Text("${d.name} (${d.quantity} ${d.unit})"),
                  subtitle: Text(
                    "Validade: ${d.validity.day}/${d.validity.month}/${d.validity.year}",
                  ),
                  trailing: Text(
                    d.status,
                    style: TextStyle(
                      color: d.status == "disponível"
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
