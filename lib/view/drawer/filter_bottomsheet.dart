import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/view/home/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoLocBottomSheet extends StatefulWidget {
  final void Function(String) onFilterSelected;
  final ValueNotifier<int?> filterNotifier;
  final String idCatalog;

  const BoLocBottomSheet({
    super.key,
    required this.onFilterSelected,
    required this.filterNotifier,
    required this.idCatalog,
  });

  @override
  State<BoLocBottomSheet> createState() => _BoLocBottomSheetState();
}

class _BoLocBottomSheetState extends State<BoLocBottomSheet> {
  List<Map<String, dynamic>> filtersWithChildren = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, List<int>> selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _fetchBoLocIncrementally(idCatalog: widget.idCatalog);
  }

  Future<void> _fetchBoLocIncrementally({required String idCatalog}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await APIService.getBoLocByCatalog(idCatalog);
      print('BoLocBottomSheet response: $response');

      if (!mounted) return;

      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> filters = response['data']['filters'] ?? [];
        final newFilters = <Map<String, dynamic>>[];

        for (var filter in filters) {
          final title = filter['name'] as String? ?? 'Bộ lọc';
          final List<dynamic> children =
              filter['children'] as List<dynamic>? ?? [];

          newFilters.add({
            'tieude': title,
            'children': children,
          });
        }

        setState(() {
          filtersWithChildren = newFilters;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load filters';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error loading filters: $e';
        isLoading = false;
      });
    }

    await loadSavedFilters();
  }

  Future<void> loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('savedFilters_${Global.email}');

    if (saved != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(saved);
        final Map<String, List<int>> restored = {};

        decoded.forEach((key, value) {
          restored[key] = List<int>.from(value);
        });

        if (mounted) {
          setState(() {
            selectedFilters = restored;
          });
        }
      } catch (e) {
        print("❌ Lỗi khi parse savedFilters: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                color: Color(0xFF198754),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bộ lọc",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text("Đóng",
                            style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                padding:
                EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                child: isLoading && filtersWithChildren.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : filtersWithChildren.isEmpty
                    ? const Center(child: Text("No filters available"))
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: filtersWithChildren.length,
                  itemBuilder: (context, index) {
                    final filter = filtersWithChildren[index];
                    final title = filter['tieude'] as String? ??
                        'Bộ lọc $index';
                    final children =
                        filter['children'] as List<dynamic>? ??
                            [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children:
                            children.map<Widget>((child) {
                              final childTitle =
                                  child['name'] as String? ??
                                      'Chi tiết';
                              final int? childId = int.tryParse(
                                  child['idfilter']?.toString() ??
                                      '');
                              final groupKey = title
                                  .toLowerCase()
                                  .replaceAll(' ', '');
                              final bool isSelected =
                                  selectedFilters[groupKey]
                                      ?.contains(childId) ??
                                      false;

                              return Stack(
                                children: [
                                  FilterChip(
                                    label: Text(
                                      childTitle,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor:
                                    const Color(0xFF198754),
                                    backgroundColor:
                                    Colors.grey[100],
                                    side: BorderSide.none,
                                    showCheckmark: false,
                                    onSelected: (selected) {
                                      if (childId != null) {
                                        setState(() {
                                          selectedFilters
                                              .putIfAbsent(
                                              groupKey,
                                                  () => []);
                                          final currentList =
                                          selectedFilters[
                                          groupKey]!;
                                          if (selected) {
                                            if (!currentList
                                                .contains(
                                                childId)) {
                                              currentList
                                                  .add(childId);
                                            }
                                          } else {
                                            currentList
                                                .remove(childId);
                                            if (currentList
                                                .isEmpty) {
                                              selectedFilters
                                                  .remove(
                                                  groupKey);
                                            }
                                          }
                                          selectedFilters[
                                          groupKey] = currentList;
                                        });
                                      }
                                    },
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  String? idFilterString;
                  if (selectedFilters.isNotEmpty) {
                    final allSelectedIds =
                    selectedFilters.values.expand((ids) => ids).toList();
                    idFilterString = allSelectedIds.join(',');
                    print('Applying filters: $idFilterString');
                  } else {
                    idFilterString = '';
                    print('No filters selected');
                  }
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('savedFilters_${Global.email}',
                      jsonEncode(selectedFilters));

                  widget.onFilterSelected(idFilterString);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text(
                  "Áp dụng",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF198754),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}