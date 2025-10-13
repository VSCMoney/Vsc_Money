import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/services/locator.dart';

import '../../../constants/colors.dart';
import '../../../models/watchlist_modal.dart';
import '../../../services/asset_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/watchlist_service.dart';



import '../../widgets/common_button.dart';
import '../search_stock_screen.dart';

final locator = GetIt.instance;

class WatchlistDetailPage extends StatefulWidget {
  final WatchlistId watchlistId;
  final VoidCallback? onTap;

  const WatchlistDetailPage({
    Key? key,
    required this.watchlistId,
    this.onTap,
  }) : super(key: key);

  @override
  State<WatchlistDetailPage> createState() => _WatchlistDetailPageState();
}

class _WatchlistDetailPageState extends State<WatchlistDetailPage> {
  final WatchlistService _svc = GetIt.I<WatchlistService>();

  // State
  WatchlistDetail? _watchlist;
  List<WatchlistStockData> _stocks = [];
  bool _loading = true;
  String? _error;
  String _sortBy = 'default'; // default, name, price, change

  // Subscriptions
  StreamSubscription<WatchlistDetail?>? _detailSub;
  StreamSubscription<String?>? _errorSub;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _detailSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Subscribe to streams
    _detailSub = _svc.detailStream.listen((detail) {
      if (!mounted) return;
      setState(() => _watchlist = detail);
      if (detail != null) {
        _loadStocksData(detail.assetIds);
      }
    });

    _errorSub = _svc.errorStream.listen((err) {
      if (!mounted || err == null) return;
      setState(() => _error = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    });

    // Load initial data
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      await _svc.openDetail(widget.watchlistId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load watchlist';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadStocksData(List<AssetId> assetIds) async {
    if (assetIds.isEmpty) {
      setState(() {
        _stocks = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ Fetch stock data for all assets in parallel
      final stockDataFutures = assetIds.map((id) =>
          WatchlistStockData.fetchFromApi(id)
      );
      final results = await Future.wait(stockDataFutures);

      if (mounted) {
        setState(() {
          // ✅ Filter out null results and populate _stocks
          _stocks = results.whereType<WatchlistStockData>().toList();
          _loading = false;
        });

        print('✅ Loaded ${_stocks.length} stocks successfully');
        for (final stock in _stocks) {
          print('  - ${stock.name}: ₹${stock.currentPrice} (${stock.changePercent}%)');
        }
      }
    } catch (e) {
      print('❌ Error loading stocks data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load stock data';
          _loading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _svc.openDetail(widget.watchlistId);
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SortBottomSheet(
        currentSort: _sortBy,
        onSortSelected: (sort) {
          setState(() => _sortBy = sort);
          Navigator.pop(context);
        },
      ),
    );
  }

  List<WatchlistStockData> _getSortedStocks() {
    final stocks = List<WatchlistStockData>.from(_stocks);

    switch (_sortBy) {
      case 'name':
        stocks.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        stocks.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case 'change':
        stocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
        break;
      default:
      // Keep original order
        break;
    }

    return stocks;
  }

  Future<void> _onEdit() async {
    if (_watchlist == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditWatchlistPage(
          watchlistId: widget.watchlistId,
          initialName: _watchlist?.name ?? "",
          initialAssets: _watchlist!.assetIds,
        ),
      ),
    );

    // Refresh if changes were saved
    if (result == true) {
      await _refresh();
    }
  }

  void _onAddStocks() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StockSearchScreen(watchlistId: widget.watchlistId),
      ),
    ).then((_) {
      // Refresh when coming back
      _refresh();
    });
  }

  void _onStockTap(WatchlistStockData stock) {
    // TODO: Navigate to stock detail page
     context.push('/asset/${stock.assetId}');
  }

  Future<void> _onRemoveStock(WatchlistStockData stock) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove stock?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Remove ${stock.name} from this watchlist?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _svc.removeFromWatchlist(
        id: widget.watchlistId,
        assetIds: [stock.assetId],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedStocks = _getSortedStocks();
    final watchlistName = _watchlist?.name ?? 'Loading...';
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _CustomAppBar(
            title: watchlistName,
            onClose: () {
              HapticFeedback.mediumImpact();
              widget.onTap!();
            },
            onEdit: _onEdit,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(
          error: _error!,
          onRetry: _refresh,
        )
            : Column(
          children: [
            // Sort and Add controls
            _ControlsRow(
              onSortTap: _showSortOptions,
              onAddTap: _onAddStocks,
            ),
            SizedBox(
              height: 20,
            ),
            // Stocks list
            Expanded(
              child: sortedStocks.isEmpty
                  ? _EmptyState(onAddTap: _onAddStocks)
                  : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedStocks.length,
                  itemBuilder: (context, index) {
                    final stock = sortedStocks[index];
                    return _StockListItem(
                      stock: stock,
                      onTap: () => _onStockTap(stock),
                      onRemove: () => _onRemoveStock(stock),
                      isLast: index == sortedStocks.length - 1,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CUSTOM APP BAR ====================

class _CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onEdit;

  const _CustomAppBar({
    required this.title,
    required this.onClose,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
       boxShadow: [
         BoxShadow(
           blurRadius: 3,
           color: Colors.grey.shade400
         )
       ]
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClose();
                  },
                  child: Image.asset(
                    "assets/images/cancel.png",
                    height: 30,
                    color: theme.icon,
                  ),
                ),

                // Title
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Edit button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onEdit?.call();
                  },
                  child: Icon(Icons.edit_rounded,color: theme.icon,)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== EMPTY STATE ====================

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAddTap;

  const _EmptyState({this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No stocks in watchlist',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add stocks to start tracking',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddTap,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add Stocks',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ERROR STATE ====================

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _ErrorState({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops!',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (onRetry != null)
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== CONTROLS ROW ====================

class _ControlsRow extends StatelessWidget {
  final VoidCallback? onSortTap;
  final VoidCallback? onAddTap;

  const _ControlsRow({
    this.onSortTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sort button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSortTap?.call();
            },
            child: Row(
              children: [
                const Text(
                  'Sort',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                // Icon(
                //   Icons.swap_vert,
                //   size: 20,
                //   color: Colors.grey.shade600,
                // ),
                SvgPicture.asset("assets/images/sort.svg")
              ],
            ),
          ),

          // Add button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onAddTap?.call();
            },
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  size: 20,
                  color: theme.icon,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockListItem extends StatelessWidget {
  final WatchlistStockData stock;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool isLast;

  const _StockListItem({
    required this.stock,
    this.onTap,
    this.onRemove,
    required this.isLast,
  });

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(2)}';
  }

  String _formatChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}';
  }

  String _formatPercent(double percent) {
    return '(${percent.toStringAsFixed(2)}%)';
  }

  @override
  Widget build(BuildContext context) {
    final changeColor = stock.isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Dismissible(
      key: Key(stock.assetId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onRemove?.call();
        return false; // Don't auto-dismiss, let the service handle it
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    // _StockLogo(
                    //   logoUrl: stock.logoUrl,
                    //   symbol: stock.symbol,
                    // ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white, // ✅ Transparent background
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset("assets/images/img_1.png")
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name and tags
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stock name
                          Text(
                            stock.name,
                            style:  TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Price and change
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current price
                        Text(
                          _formatPrice(stock.currentPrice),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Change amount and percent
                        Text(
                          '${_formatChange(stock.changeAmount)} ${_formatPercent(stock.changePercent)}',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: changeColor,
                            height: 1.3,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _TagsRow(tags: stock.tags),
                ],
              ),
             SizedBox(height: 18,),
              if (!isLast)
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== STOCK LOGO ====================

class _StockLogo extends StatelessWidget {
  final String? logoUrl;
  final String symbol;

  const _StockLogo({
    this.logoUrl,
    required this.symbol,
  });

  Color _getColorFromSymbol(String symbol) {
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    final hash = symbol.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            logoUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _FallbackLogo(
                symbol: symbol,
                color: _getColorFromSymbol(symbol),
              );
            },
          ),
        ),
      );
    }

    return _FallbackLogo(
      symbol: symbol,
      color: _getColorFromSymbol(symbol),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final String symbol;
  final Color color;

  const _FallbackLogo({
    required this.symbol,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initials = symbol.length >= 2
        ? symbol.substring(0, 2).toUpperCase()
        : symbol.toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.12),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ==================== TAGS ROW ====================

class _TagsRow extends StatelessWidget {
  final List<String> tags;

  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) => _TagChip(label: tag)).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  Color _getChipColor(String label) {
    final lowerLabel = label.toLowerCase();

    if (lowerLabel.contains('groww') || lowerLabel.contains('growth')) {
      return const Color(0xFF10B981);
    } else if (lowerLabel.contains('mutual fund') || lowerLabel.contains('mf')) {
      return const Color(0xFF3B82F6);
    } else if (lowerLabel.contains('sip')) {
      return const Color(0xFF8B5CF6);
    } else if (lowerLabel.contains('investment')) {
      return const Color(0xFF06B6D4);
    } else if (label.startsWith('+')) {
      return const Color(0xFF6B7280);
    }

    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _getChipColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chipColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.contains('Groww'))
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor.withOpacity(0.9),
              height: 1.2,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SORT BOTTOM SHEET ====================

class _SortBottomSheet extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;

  const _SortBottomSheet({
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Sort by',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            // Sort options
            _SortOption(
              label: 'Default',
              value: 'default',
              currentSort: currentSort,
              onTap: () => onSortSelected('default'),
            ),
            _SortOption(
              label: 'Name (A-Z)',
              value: 'name',
              currentSort: currentSort,
              onTap: () => onSortSelected('name'),
            ),
            _SortOption(
              label: 'Price (High to Low)',
              value: 'price',
              currentSort: currentSort,
              onTap: () => onSortSelected('price'),
            ),
            _SortOption(
              label: 'Change % (High to Low)',
              value: 'change',
              currentSort: currentSort,
              onTap: () => onSortSelected('change'),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final String value;
  final String currentSort;
  final VoidCallback onTap;
  final bool isLast;

  const _SortOption({
    required this.label,
    required this.value,
    required this.currentSort,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentSort == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 20,
                color: Color(0xFF10B981),
              ),
          ],
        ),
      ),
    );
  }
}











class EditWatchlistPage extends StatefulWidget {
  final WatchlistId watchlistId;
  final String initialName;
  final List<AssetId> initialAssets;

  const EditWatchlistPage({
    Key? key,
    required this.watchlistId,
    required this.initialName,
    required this.initialAssets,
  }) : super(key: key);

  @override
  State<EditWatchlistPage> createState() => _EditWatchlistPageState();
}

class _EditWatchlistPageState extends State<EditWatchlistPage> {
  final WatchlistService _svc = GetIt.I<WatchlistService>();

  late TextEditingController _nameController;
  late List<AssetId> _currentAssets;
  bool _hasChanges = false;
  bool _saving = false;
  final Map<AssetId, String> _assetNames = {};
  bool _loadingNames = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _currentAssets = List.from(widget.initialAssets);
    _loadStockNames();
    _nameController.addListener(() {
      _checkForChanges();
    });
  }


  Future<void> _loadStockNames() async {
    final futures = _currentAssets.map((assetId) async {
      final assetService = AssetService();
      await assetService.init(assetId: assetId, sections: {Section.overview});

      await Future.delayed(const Duration(milliseconds: 300));

      final name = assetService.snapshot.data?.basicInfo?.name ?? assetId;
      assetService.dispose();

      return MapEntry(assetId, name);
    });

    final results = await Future.wait(futures);

    setState(() {
      for (final entry in results) {
        _assetNames[entry.key] = entry.value;
      }
      _loadingNames = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != widget.initialName;
    final assetsChanged = !_listEquals(_currentAssets, widget.initialAssets);

    setState(() {
      _hasChanges = nameChanged || assetsChanged;
    });
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _removeStock(AssetId assetId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentAssets.remove(assetId);
    });
    _checkForChanges();
  }

  void _onReorder(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _currentAssets.removeAt(oldIndex);
      _currentAssets.insert(newIndex, item);
    });
    _checkForChanges();
  }

  Future<void> _deleteWatchlist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Watchlist?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.initialName}"? This action cannot be undone.',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _svc.removeWatchlist(widget.watchlistId);

      if (!mounted) return;

      if (success) {
        // Pop twice: once for dialog, once for edit page, once for detail page
        Navigator.of(context).pop(); // Edit page
        Navigator.of(context).pop(); // Detail page

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watchlist deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete watchlist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watchlist name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // 1. Update name if changed
      if (newName != widget.initialName) {
        await _svc.editWatchlist(
          id: widget.watchlistId,
          name: newName,
        );
      }

      // 2. Handle removed stocks
      final removedAssets = widget.initialAssets
          .where((asset) => !_currentAssets.contains(asset))
          .toList();

      if (removedAssets.isNotEmpty) {
        await _svc.removeFromWatchlist(
          id: widget.watchlistId,
          assetIds: removedAssets,
        );
      }

      // 3. ✅ UPDATE ORDER if changed (ADD THIS)
      if (!_listEquals(_currentAssets, widget.initialAssets)) {
        await _svc.reorderWatchlistAssets(
          id: widget.watchlistId,
          orderedAssetIds: _currentAssets,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watchlist updated')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard changes?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
     child : WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: theme.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _EditAppBar(
              onBack: () async {
                if (await _onWillPop()) {
                  Navigator.of(context).pop();
                }
              },
              onDelete: _deleteWatchlist,
            ),
          ),
          body: Column(
            children: [
              // Name input field
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Watchlist name',
                    hintStyle: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: theme.background,
                    ),
                    filled: true,
                   // fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              // Stocks list with reordering
              Expanded(
                child: _currentAssets.isEmpty
                    ? _EmptyState()
                    : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onReorder: _onReorder,
                  itemCount: _currentAssets.length,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final assetId = _currentAssets[index];
                    final isLast = index == _currentAssets.length - 1;

                    return _StockEditItem(
                      displayname: _assetNames[assetId]?? assetId,
                      index: index,
                      key: ValueKey(assetId),
                      assetId: assetId,
                      onRemove: () => _removeStock(assetId),
                      isLast: isLast,
                    );
                  },
                ),
              ),
              // Save button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: theme.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: CommonButton(
                    label: _saving ? 'Saving...' : 'Save',
                    onPressed: (_saving || !_hasChanges) ? null : _save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== EDIT APP BAR ====================

class _EditAppBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const _EditAppBar({
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onBack();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    // decoration: BoxDecoration(
                    //   color: Colors.grey.shade100,
                    //   shape: BoxShape.circle,
                    // ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Title
                const Expanded(
                  child: Center(
                    child: Text(
                      'Edit Watchlist',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                // Delete button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onDelete();
                  },
                  child: SvgPicture.asset("assets/images/delete.svg"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== STOCK EDIT ITEM ====================



class _StockEditItem extends StatelessWidget {
  final String displayname;
  final int index;
  final AssetId assetId;
  final VoidCallback onRemove;
  final bool isLast;

  const _StockEditItem({
    Key? key,
    required this.displayname,
    required this.index,
    required this.assetId,
    required this.onRemove,
    required this.isLast,
  }) : super(key: key);

  String _getStockName(AssetId assetId) {
    // Mock data - replace with actual stock name lookup
    final mockNames = {
      'HDFCBANK': 'HDFC Bank',
      'ICICIBANK': 'ICICI Bank',
      'TCS': 'Tata Consultancy Services',
      'INFY': 'Infosys',
      'RELIANCE': 'Reliance Industries',
      'NFLX': 'Netflix',
      'GOOGL': 'Alphabet Inc',
      'MSFT': 'Microsoft Corporation',
      'TATASTEEL': 'Tata Steel',
      'DIS': 'Walt Disney Co',
    };

    return mockNames[assetId] ?? assetId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
          // decoration: BoxDecoration(
          //   color: Colors.white,
          //   borderRadius: BorderRadius.circular(12),
          //   border: Border.all(
          //     color: Colors.grey.shade200,
          //     width: 1,
          //   ),
          // ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Row(
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      width: 18,
                      height: 18,
                      // decoration: BoxDecoration(
                      //   color: Colors.grey.shade100,
                      //   borderRadius: BorderRadius.circular(6),
                      // ),
                      child: SvgPicture.asset("assets/images/reorder.svg",height: 28,width: 8,fit: BoxFit.fitWidth,)
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Stock name
                  Expanded(
                    child: Text(
                      _getStockName(displayname),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Remove button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onRemove();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      // decoration: BoxDecoration(
                      //   color: Colors.red.shade50,
                      //   borderRadius: BorderRadius.circular(6),
                      // ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(color: Colors.grey.shade200,)
      ],
    );
  }
}





