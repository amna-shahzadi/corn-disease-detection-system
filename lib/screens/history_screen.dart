import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  const HistoryScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // List of all history items
  final List<HistoryItem> _allHistoryItems = [
    HistoryItem(
      title: 'Disease Detected',
      subTitle: 'Gray Leaf Spot',
      date: '2023-10-26',
      time: '14:30',
      isHealthy: false,
      diseaseType: 'Gray Leaf Spot',
      originalOrder: 0,
    ),
    HistoryItem(
      title: 'Healthy Leaf',
      subTitle: 'No disease detected',
      date: '2023-10-26',
      time: '09:15',
      isHealthy: true,
      diseaseType: null,
      originalOrder: 1,
    ),
    HistoryItem(
      title: 'Disease Detected',
      subTitle: 'Fusarium Ear Root',
      date: '2023-10-25',
      time: '11:00',
      isHealthy: false,
      diseaseType: 'Fusarium Ear Root',
      originalOrder: 2,
    ),
    HistoryItem(
      title: 'Healthy Leaf',
      subTitle: 'No disease detected',
      date: '2023-10-24',
      time: '16:45',
      isHealthy: true,
      diseaseType: null,
      originalOrder: 3,
    ),
    HistoryItem(
      title: 'Disease Detected',
      subTitle: 'Common Rust',
      date: '2023-10-23',
      time: '10:30',
      isHealthy: false,
      diseaseType: 'Common Rust',
      originalOrder: 4,
    ),
  ];

  // Filter state
  FilterType _currentFilter = FilterType.showAll;
  bool _isDateSortedDescending = true; // Newest first by default

  // Get filtered and sorted items
  List<HistoryItem> get _filteredItems {
    List<HistoryItem> items = List.from(_allHistoryItems);

    // Apply filter
    switch (_currentFilter) {
      case FilterType.healthyOnly:
        items = items.where((item) => item.isHealthy).toList();
        break;
      case FilterType.diseaseOnly:
        items = items.where((item) => !item.isHealthy).toList();
        break;
      case FilterType.showAll:
        // No filter applied
        break;
    }

    // Apply sorting
    items.sort((a, b) {
      if (_isDateSortedDescending) {
        // Sort by date descending (newest first)
        return b.date.compareTo(a.date);
      } else {
        // Sort by date ascending (oldest first)
        return a.date.compareTo(b.date);
      }
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Row(
              children: [
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const Spacer(),
                // Filter/Search button with badge if filtered
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        _showFilterOptions(context);
                      },
                      icon: Icon(
                        Icons.filter_list,
                        color: _currentFilter != FilterType.showAll
                            ? Colors.green[700]
                            : Colors.grey.shade700,
                      ),
                    ),
                    // Show badge when filter is active
                    if (_currentFilter != FilterType.showAll)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Show active filter chip
          if (_currentFilter != FilterType.showAll)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(
                      _currentFilter == FilterType.healthyOnly
                          ? 'Healthy Only'
                          : 'Disease Only',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    selected: true,
                    onSelected: null,
                    backgroundColor: Colors.green[700],
                    selectedColor: Colors.green[700],
                    checkmarkColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentFilter = FilterType.showAll;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // History List
          Column(
            children: _filteredItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildHistoryCard(
                      title: item.title,
                      subTitle: item.subTitle,
                      date: item.date,
                      time: item.time,
                      isHealthy: item.isHealthy,
                      diseaseType: item.diseaseType,
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String subTitle,
    required String date,
    required String time,
    required bool isHealthy,
    String? diseaseType,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle/Disease name
                Text(
                  subTitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isHealthy ? Colors.grey.shade600 : Colors.orange.shade800,
                    fontWeight: isHealthy ? FontWeight.normal : FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Date and Time
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHealthy ? Colors.green.shade200 : Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Text(
              isHealthy ? 'Healthy' : 'Disease',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isHealthy ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to show filter options
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filter History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(
                'Show All',
                Icons.list,
                FilterType.showAll,
                _currentFilter == FilterType.showAll,
              ),
              _buildFilterOption(
                'Healthy Only',
                Icons.check_circle,
                FilterType.healthyOnly,
                _currentFilter == FilterType.healthyOnly,
              ),
              _buildFilterOption(
                'Disease Only',
                Icons.warning,
                FilterType.diseaseOnly,
                _currentFilter == FilterType.diseaseOnly,
              ),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                'Sort Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              _buildSortOption(
                'Newest First',
                Icons.arrow_downward,
                true,
                _isDateSortedDescending,
              ),
              _buildSortOption(
                'Oldest First',
                Icons.arrow_upward,
                false,
                !_isDateSortedDescending,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
      String title, IconData icon, FilterType filterType, bool isSelected) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentFilter = filterType;
        });
      },
      leading: Icon(
        icon,
        color: isSelected ? Colors.green[700] : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.green[900] : Colors.grey.shade800,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Colors.green[700],
            )
          : null,
    );
  }

  Widget _buildSortOption(
      String title, IconData icon, bool isDescending, bool isSelected) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _isDateSortedDescending = isDescending;
        });
      },
      leading: Icon(
        icon,
        color: isSelected ? Colors.green[700] : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.green[900] : Colors.grey.shade800,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Colors.green[700],
            )
          : null,
    );
  }
}

// Data model for history items
class HistoryItem {
  final String title;
  final String subTitle;
  final String date;
  final String time;
  final bool isHealthy;
  final String? diseaseType;
  final int originalOrder;

  HistoryItem({
    required this.title,
    required this.subTitle,
    required this.date,
    required this.time,
    required this.isHealthy,
    required this.diseaseType,
    required this.originalOrder,
  });
}

// Filter types
enum FilterType {
  showAll,
  healthyOnly,
  diseaseOnly,
}