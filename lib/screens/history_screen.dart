import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final String? userId;

  const HistoryScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.userId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  List<HistoryItem> _allHistoryItems = [];
  FilterType _currentFilter = FilterType.showAll;
  bool _isDateSortedDescending = true;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool silent = false}) async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.historyUserNotIdentified;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _allHistoryItems.clear();
      });
    }

    try {
      final responses = await ApiService.getHistory(userId: userId, page: 1);
      final items = <HistoryItem>[];
      for (var i = 0; i < responses.length; i++) {
        final h = responses[i];
        final isHealthy = h.isHealthy;
        final title =
            h.title ?? (isHealthy ? 'Healthy Leaf' : 'Disease Detected');
        final subTitle = h.diseaseName ??
            (isHealthy
                ? 'No disease detected'
                : (h.raw?['status']?.toString() ?? 'Disease detected'));
        items.add(HistoryItem(
          id: h.id ?? 'item_$i',
          title: title,
          subTitle: subTitle,
          date: h.date ?? '',
          time: h.time ?? '',
          isHealthy: isHealthy,
          diseaseType: h.diseaseName,
          originalOrder: i,
        ));
      }
      setState(() {
        _allHistoryItems = items;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on ApiException {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.historyFailedToLoad;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.historyFailedToLoad + ': $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshHistory() async {
    setState(() => _isRefreshing = true);
    _refreshController.repeat();
    await _loadHistory(silent: true);
    _refreshController.stop();
    _refreshController.reset();
  }

  List<HistoryItem> get _filteredItems {
    List<HistoryItem> items = List.from(_allHistoryItems);
    switch (_currentFilter) {
      case FilterType.healthyOnly:
        items = items.where((item) => item.isHealthy).toList();
        break;
      case FilterType.diseaseOnly:
        items = items.where((item) => !item.isHealthy).toList();
        break;
      case FilterType.showAll:
        break;
    }
    items.sort((a, b) => _isDateSortedDescending
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      body: SafeArea(
        child: RefreshIndicator(
          color: Color(0xFF1B5E20),
          onRefresh: _refreshHistory,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  child: Column(
                    children: [
                      _buildHeaderContent(),
                      _buildFilterChips(),
                    ],
                  ),
                ),
              ),
              _buildContent(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
      color: const Color(0xFFF6F8F3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.historyTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (_allHistoryItems.isNotEmpty)
             Text(
  '${AppLocalizations.of(context)!.historyTotalScans} ${_allHistoryItems.length}',
  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
) ],
            ),
          ),
          // Refresh button with spin animation
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              onPressed: _isRefreshing ? null : _refreshHistory,
              icon: Icon(
                Icons.refresh_rounded,
                color: _isRefreshing ? Color(0xFF1B5E20) : Colors.grey.shade600,
                size: 22,
              ),
            ),
          ),
          // Filter button
          Stack(
            children: [
              IconButton(
                onPressed: () => _showFilterSheet(context),
                icon: Icon(
                  Icons.tune_rounded,
                  color: _currentFilter != FilterType.showAll
                      ? Color(0xFF1B5E20)
                      : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              if (_currentFilter != FilterType.showAll)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B5E20),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      color: const Color(0xFFF6F8F3),
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _filterChip(AppLocalizations.of(context)!.historyFilterAll,
                FilterType.showAll, Icons.apps_rounded),
            const SizedBox(width: 6),
            _filterChip(AppLocalizations.of(context)!.historyFilterHealthy,
                FilterType.healthyOnly, Icons.check_circle_outline_rounded),
            const SizedBox(width: 6),
            _filterChip(AppLocalizations.of(context)!.historyFilterDiseased,
                FilterType.diseaseOnly, Icons.warning_amber_rounded),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, FilterType type, IconData icon) {
    final isActive = _currentFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? Color(0xFF1B5E20) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: isActive ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.historyLoading,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadHistory,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.commonRetry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = _filteredItems;
    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.eco_rounded,
                      size: 40, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 20),
                Text(
                  _currentFilter == FilterType.showAll
                      ? AppLocalizations.of(context)!.historyNoScans
                      : AppLocalizations.of(context)!
                          .historyNoHealthyScans
                          .replaceAll(
                              'healthy',
                              _currentFilter == FilterType.healthyOnly
                                  ? AppLocalizations.of(context)!.historyHealthyBadge.toLowerCase()
                                  : AppLocalizations.of(context)!.historyDiseaseBadge.toLowerCase()),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.historyStartScanning,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryCard(
                item: item,
                onTap: () => _openDetailSheet(context, item),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  // ─── Detail bottom sheet ───────────────────────────────────────────────────
  void _openDetailSheet(BuildContext context, HistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailSheet(item: item),
    );
  }

  // ─── Filter bottom sheet ──────────────────────────────────────────────────
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.historyFilterSortTitle,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sheetLabel(AppLocalizations.of(context)!.historyFilterByLabel),
                  _filterTile(ctx, setModalState, AppLocalizations.of(context)!.historyShowAll,
                      Icons.apps_rounded, FilterType.showAll),
                  _filterTile(
                      ctx,
                      setModalState,
                      AppLocalizations.of(context)!.historyHealthyOnly,
                      Icons.check_circle_outline_rounded,
                      FilterType.healthyOnly),
                  _filterTile(ctx, setModalState, AppLocalizations.of(context)!.historyDiseaseOnly,
                      Icons.warning_amber_rounded, FilterType.diseaseOnly),
                  Divider(color: Colors.grey.shade500, height: 24),
                  _sheetLabel(AppLocalizations.of(context)!.historySortByLabel),
                  _sortTile(ctx, setModalState, AppLocalizations.of(context)!.historyNewestFirst,
                      Icons.arrow_downward_rounded, true),
                  _sortTile(ctx, setModalState, AppLocalizations.of(context)!.historyOldestFirst,
                      Icons.arrow_upward_rounded, false),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
                letterSpacing: 0.8)),
      );

  Widget _filterTile(BuildContext ctx, StateSetter setModal, String title,
      IconData icon, FilterType type) {
    final selected = _currentFilter == type;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon,
          color: selected ? Color(0xFF1B5E20) : Colors.grey.shade500, size: 20),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Color(0xFF1B5E20) : Colors.grey.shade800)),
      trailing: selected
          ? Icon(Icons.check_rounded, color: Color(0xFF1B5E20), size: 20)
          : null,
      onTap: () {
        setModal(() {});
        setState(() => _currentFilter = type);
        Navigator.pop(ctx);
      },
    );
  }

  Widget _sortTile(BuildContext ctx, StateSetter setModal, String title,
      IconData icon, bool descending) {
    final selected = _isDateSortedDescending == descending;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon,
          color: selected ? Color(0xFF1B5E20) : Colors.grey.shade500, size: 20),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Color(0xFF1B5E20) : Colors.grey.shade800)),
      trailing: selected
          ? Icon(Icons.check_rounded, color: Color(0xFF1B5E20), size: 20)
          : null,
      onTap: () {
        setModal(() {});
        setState(() => _isDateSortedDescending = descending);
        Navigator.pop(ctx);
      },
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored accent bar
                Container(
                  width: 4,
                  color: item.isHealthy
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF57C00),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.isHealthy
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: item.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('History image load error: $error');
                                      return _leafIcon(item.isHealthy);
                                    },
                                  ),
                                )
                              : _leafIcon(item.isHealthy),
                        ),

                        const SizedBox(width: 14),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusBadge(isHealthy: item.isHealthy),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.isHealthy
                                      ? Colors.grey.shade500
                                      : Colors.orange.shade700,
                                  fontWeight: item.isHealthy
                                      ? FontWeight.normal
                                      : FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetaChip(
                                        icon: Icons.calendar_today_outlined,
                                        label: item.date),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MetaChip(
                                        icon: Icons.access_time_rounded,
                                        label: item.time),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leafIcon(bool healthy) {
    return Icon(
      Icons.eco_rounded,
      color: healthy ? Colors.green.shade300 : Colors.orange.shade300,
      size: 28,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isHealthy;
  const _StatusBadge({required this.isHealthy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHealthy ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Text(
        isHealthy ? AppLocalizations.of(context)!.historyHealthyBadge : AppLocalizations.of(context)!.historyDiseaseBadge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isHealthy ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11, 
              color: Colors.grey.shade500
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Detail Bottom Sheet ──────────────────────────────────────────────────────
class _DetailSheet extends StatefulWidget {
  final HistoryItem item;
  const _DetailSheet({required this.item});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  int? _selectedLabel;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.isHealthy ? item.title : item.subTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  _StatusBadge(isHealthy: item.isHealthy),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${item.date}  ·  ${item.time}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 18),

              // Leaf image with hotspots
              _LeafImageWithHotspots(
                imageUrl: item.imageUrl,
                labels: item.diseaseLabels,
                isHealthy: item.isHealthy,
                selectedIndex: _selectedLabel,
                onLabelTap: (i) => setState(
                    () => _selectedLabel = _selectedLabel == i ? null : i),
              ),

              const SizedBox(height: 18),

              // Stats row
              if (!item.isHealthy)
                Row(
                  children: [
                    if (item.confidence != null)
                      _StatCard(
                          label: 'Confidence',
                          value: item.confidence!,
                          icon: Icons.analytics_outlined,
                          color: Colors.blue),
                    if (item.confidence != null && item.severity != null)
                      const SizedBox(width: 10),
                    if (item.severity != null)
                      _StatCard(
                          label: 'Severity',
                          value: item.severity!,
                          icon: Icons.warning_amber_rounded,
                          color: item.severity!.toLowerCase() == 'severe'
                              ? Colors.red
                              : Colors.orange),
                  ],
                ),

              if (!item.isHealthy && item.diseaseLabels.isNotEmpty)
                const SizedBox(height: 18),

              // Disease label list
              if (item.diseaseLabels.isNotEmpty) ...[
                Text(
                  item.isHealthy ? 'Observations' : 'Affected areas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                ...item.diseaseLabels.asMap().entries.map(
                      (e) => _LabelRow(
                        index: e.key,
                        label: e.value,
                        isHealthy: item.isHealthy,
                        isSelected: _selectedLabel == e.key,
                        onTap: () => setState(() => _selectedLabel =
                            _selectedLabel == e.key ? null : e.key),
                      ),
                    ),
              ],

              // Tip / recommendation
              if (item.tip != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.isHealthy
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.isHealthy
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: item.isHealthy
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.tip!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: item.isHealthy
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Leaf Image with Hotspot Overlays ─────────────────────────────────────────
class _LeafImageWithHotspots extends StatelessWidget {
  final String? imageUrl;
  final List<DiseaseLabel> labels;
  final bool isHealthy;
  final int? selectedIndex;
  final void Function(int) onLabelTap;

  const _LeafImageWithHotspots({
    required this.imageUrl,
    required this.labels,
    required this.isHealthy,
    required this.selectedIndex,
    required this.onLabelTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            if (imageUrl != null)
              Image.network(imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
            else
              _placeholder(),

            // Semi-transparent scrim when hotspots exist
            if (labels.isNotEmpty)
              Container(color: Colors.black.withOpacity(0.08)),

            // Hotspot overlays
            ...labels.asMap().entries.map((e) {
              final i = e.key;
              final label = e.value;
              final isSelected = selectedIndex == i;
              // Convert normalised offsets (0–1) to actual positions
              return Positioned(
                left: label.x * MediaQuery.of(context).size.width * 0.85 -
                    (isSelected ? 16 : 12),
                top: label.y *
                        (MediaQuery.of(context).size.width * 0.85 * 0.75) -
                    (isSelected ? 16 : 12),
                child: GestureDetector(
                  onTap: () => onLabelTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 32 : 24,
                    height: isSelected ? 32 : 24,
                    decoration: BoxDecoration(
                      color: isHealthy
                          ? Colors.green.withOpacity(0.9)
                          : Colors.orange.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: (isHealthy ? Colors.green : Colors.orange)
                              .withOpacity(0.5),
                          blurRadius: isSelected ? 10 : 4,
                          spreadRadius: isSelected ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Tap-to-explore hint
            if (labels.isNotEmpty)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('Tap dots to explore',
                          style:
                              TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: isHealthy ? Colors.green.shade50 : Colors.orange.shade50,
      child: Center(
        child: Icon(Icons.eco_rounded,
            size: 64,
            color: isHealthy ? Colors.green.shade200 : Colors.orange.shade200),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final int index;
  final DiseaseLabel label;
  final bool isHealthy;
  final bool isSelected;
  final VoidCallback onTap;

  const _LabelRow({
    required this.index,
    required this.label,
    required this.isHealthy,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isHealthy ? Color(0xFF1B5E20) : Colors.orange.shade50)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isHealthy ? Color(0xFF1B5E20) : Colors.orange.shade300)
                : Colors.grey.shade500,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isHealthy ? Color(0xFF1B5E20) : Colors.orange[600])
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (label.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      label.description!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color.shade600),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: color.shade600)),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color.shade800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header Delegate ─────────────────────────────────────────────────────────────
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _HeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 148.0;

  @override
  double get minExtent => 148.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────

/// A single annotated region on the leaf image.
class DiseaseLabel {
  final String name;
  final String? description;

  /// Normalised position [0.0–1.0] relative to image width/height.
  final double x;
  final double y;

  const DiseaseLabel({
    required this.name,
    this.description,
    required this.x,
    required this.y,
  });
}

class HistoryItem {
  final String id;
  final String title;
  final String subTitle;
  final String date;
  final String time;
  final bool isHealthy;
  final String? diseaseType;
  final String? imageUrl;
  final String? confidence;
  final String? severity;
  final List<DiseaseLabel> diseaseLabels;
  final String? tip;
  final int originalOrder;

  HistoryItem({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.date,
    required this.time,
    required this.isHealthy,
    required this.diseaseType,
    this.imageUrl,
    this.confidence,
    this.severity,
    this.diseaseLabels = const [],
    this.tip,
    required this.originalOrder,
  });
}

enum FilterType { showAll, healthyOnly, diseaseOnly }
