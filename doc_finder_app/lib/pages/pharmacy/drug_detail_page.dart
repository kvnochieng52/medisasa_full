import 'package:xyvra_health/pages/pharmacy/checkout_page.dart';
import 'package:xyvra_health/pages/pharmacy/models/drug.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DrugDetailPage extends StatelessWidget {
  final Drug drug; // Accept a Drug object

  const DrugDetailPage({
    Key? key,
    required this.drug,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          drug.name,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ), // Use drug name for the title
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: const Color(0xFF008faf),
      ),
      body: SingleChildScrollView(
        // Make the body scrollable
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Card with Drug Details
            Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.asset(
                      drug.image,
                      height: 300,
                      fit: BoxFit.cover,
                      width: double.infinity, // Full width
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drug.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Row for Pharmacy
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pharmacy: ${drug.pharmacy}', // Supplier name
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row for Price and Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KES ${drug.price}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Distance with Pin Icon
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.red, // Pin icon color
                                ),
                                const SizedBox(
                                    width: 4), // Space between icon and text
                                const Text(
                                  '5km away',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20), // Space before buttons
                        // Add to Cart Button
                        SizedBox(
                          width: double.infinity, // Full width
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showAddToCartDialog(context);
                            },
                            icon: const Icon(
                                Icons.shopping_cart), // Icon for the button
                            label: const Text('Add to Cart'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF008faf),
                                foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8), // Space between buttons
                        // Checkout Button
                        SizedBox(
                          width: double.infinity, // Full width
                          child: OutlinedButton(
                            onPressed: () {
                              context.go('/cart');
                            },
                            child: const Text(
                              'Checkout',
                              style: const TextStyle(
                                  fontSize: 16, color: Color(0xFF008faf)),
                            ),
                            style: OutlinedButton.styleFrom(
                              // Text color
                              side: const BorderSide(
                                  color: Color(0xFF008faf)), // Border color
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Second Card for Description
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                      'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                      'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                      'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '
                      'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
                      'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia '
                      'deserunt mollit anim id est laborum.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show Add to Cart dialog
  // Method to show Add to Cart dialog
  void _showAddToCartDialog(BuildContext context) {
    int quantity = 1; // Default quantity

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add ${drug.name} to Cart',
              style: const TextStyle(fontSize: 18)), // Updated title
          content: SizedBox(
            height: 80, // Set a fixed height for the dialog
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Minus Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red, // Red background for minus button
                        borderRadius: BorderRadius.circular(30), // Round border
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            quantity--;
                            (context as Element)
                                .markNeedsBuild(); // Rebuild the dialog to reflect changes
                          }
                        },
                        icon: const Icon(Icons.remove,
                            color: Colors.white), // White icon color
                      ),
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    // Plus Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green, // Green background for plus button
                        borderRadius: BorderRadius.circular(30), // Round border
                      ),
                      child: IconButton(
                        onPressed: () {
                          quantity++;
                          (context as Element)
                              .markNeedsBuild(); // Rebuild the dialog to reflect changes
                        },
                        icon: const Icon(Icons.add,
                            color: Colors.white), // White icon color
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Implement add to cart functionality here

                // Show the snack bar message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${drug.name} successfully added to cart!'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Add to Cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008faf),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
