import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../bo/cart.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPaymentMethod = '';
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    Cart cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Finalisation de la commande"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildOrderSummaryCard(context, cart),
            SizedBox(height: 16),
            buildDeliveryAddressCard(context),
            SizedBox(height: 16),
            buildPaymentMethodsCard(context),
            Spacer(),
            const Text(
              "En cliquant sur \"Confirmer l'achat\", vous acceptez les conditions de vente de EPSI Shop International. Besoin d'aide ? Contactez-nous",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: isSubmitting ? null : () => submitOrder(cart),
              child: isSubmitting ? CircularProgressIndicator() : Text("Confirmer l'achat"),
            ),
          ],
        ),
      ),
    );
  }

  void submitOrder(Cart cart) async {
    setState(() {
      isSubmitting = true;
    });

    // Construction du corps de la requête
    var body = json.encode({
      "total": getTotalPrice(cart),
      "adresse": "Lefay Alexandre,123 Rue Imaginaire, 75000 Paris",
      "paymentMethode": selectedPaymentMethod
    });

    try {
      var response = await http.post(
        Uri.parse("http://ptsv3.com/t/EPSISHOPC1/"),
        body: body,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Votre commande est validée avec $selectedPaymentMethod")),
        );
        cart.clearCart();
        GoRouter.of(context).go('/cart');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la validation de la commande")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Widget buildOrderSummaryCard(BuildContext context, Cart cart) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Récapitulatif de la commande", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Sous-Total: ${formatPrice(getTotalPrice(cart) - getTvaFromTotalPrice(cart))}€"),
            SizedBox(height: 8),
            Text("TVA: ${formatPrice(getTvaFromTotalPrice(cart))}€"),
            SizedBox(height: 8),
            Text("TOTAL: ${formatPrice(getTotalPrice(cart))}€", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildDeliveryAddressCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Adresse de livraison", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Lefay Alexandre", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("123 Rue Imaginaire,"),
            Text("75000 Paris"),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentMethodsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Méthodes de paiement",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                paymentChip("Apple Pay", FontAwesomeIcons.applePay),
                paymentChip("Visa", FontAwesomeIcons.ccVisa),
                paymentChip("Mastercard", FontAwesomeIcons.ccMastercard),
                paymentChip("PayPal", FontAwesomeIcons.ccPaypal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentChip(String label, IconData icon) {
    bool isSelected = label == selectedPaymentMethod;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = label;
        });
      },
      child: Chip(
        label: Text(label),
        avatar: Icon(icon),
        backgroundColor: isSelected ? Theme.of(context).colorScheme.secondary : null,
        side: isSelected ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
    );
  }

  String formatPrice(double price) {
    return price.toStringAsFixed(2);
  }

  double getTotalPrice(Cart cart) {
    double totalPrice = 0.0;
    for (var article in cart.items) {
      totalPrice += article.prix;
    }
    return totalPrice;
  }

  double getTvaFromTotalPrice(Cart cart) {
    double tva = 0.0;
    for (var article in cart.items) {
      tva += article.prix * 0.2; // 20% de TVA
    }
    return tva;
  }
}
