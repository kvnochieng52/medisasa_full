import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/services/medicine_service.dart';
import 'package:xyvra_health/models/medicine/medicine_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class InStoreSectionWidget extends StatefulWidget {
  const InStoreSectionWidget({Key? key}) : super(key: key);

  @override
  State<InStoreSectionWidget> createState() => _InStoreSectionWidgetState();
}

class _InStoreSectionWidgetState extends State<InStoreSectionWidget> {
  final AuthService _authService = AuthService();
  List<Medicine> _recentMedicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentMedicines();
  }

  Future<void> _loadRecentMedicines() async {
    try {
      debugPrint('Loading recent medicines using MedicineService...');

      final response = await MedicineService.getMedicines(
        page: 1,
        perPage: 5,
        sortBy: 'created_at',
        sortOrder: 'desc',
      );

      debugPrint('Successfully loaded ${response.medicines.length} medicines');

      setState(() {
        _recentMedicines = response.medicines;
        _isLoading = false;
      });

      if (_recentMedicines.isEmpty) {
        debugPrint('WARNING: No medicines found. Check if medicines are marked as active (is_active = 1) in database');
      }
    } catch (e) {
      debugPrint('Error loading recent medicines: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and "View All"
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008faf).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: Color(0xFF008faf),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recent Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/shop');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008faf).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF008faf),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF008faf),
                    ),
                  )
                : _recentMedicines.isEmpty
                    ? const Center(
                        child: Text(
                          'No medicines available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _recentMedicines.length,
                        itemBuilder: (context, index) {
                          final medicine = _recentMedicines[index];
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: medicine.imageUrl.isNotEmpty
                                      ? Image.network(
                                          medicine.imageUrl,
                                          height: 90,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 90,
                                              width: double.infinity,
                                              color: const Color(0xFF008faf).withOpacity(0.1),
                                              child: const Icon(
                                                Icons.medical_services,
                                                color: Color(0xFF008faf),
                                                size: 40,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          height: 90,
                                          width: double.infinity,
                                          color: const Color(0xFF008faf).withOpacity(0.1),
                                          child: const Icon(
                                            Icons.medical_services,
                                            color: Color(0xFF008faf),
                                            size: 40,
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3748),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        medicine.formattedCost,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF008faf),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${medicine.name} added to cart'),
                                                backgroundColor: const Color(0xFF008faf),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF008faf),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'Add to Cart',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                            },
                          ),
              ),
          // More Products & Medicines button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/shop');
                },
                icon: const Icon(Icons.store, size: 18),
                label: const Text(
                  'View All Products',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF008faf),
                  side: const BorderSide(color: Color(0xFF008faf)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}