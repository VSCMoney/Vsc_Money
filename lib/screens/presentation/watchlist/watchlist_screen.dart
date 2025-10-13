import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:vscmoney/constants/bottomsheet.dart';
import 'package:vscmoney/constants/app_bar.dart';
import 'package:vscmoney/constants/colors.dart';

import 'package:vscmoney/models/watchlist_modal.dart';
import 'package:vscmoney/services/watchlist_service.dart';
import 'package:vscmoney/services/locator.dart' show locator;

import 'package:vscmoney/screens/presentation/watchlist/watchlist_detail.dart';
import 'package:vscmoney/screens/presentation/search_stock_screen.dart';
import 'package:vscmoney/screens/widgets/common_button.dart';
import 'package:vscmoney/screens/widgets/drawer.dart';

import '../../../services/theme_service.dart';


/// Design tokens tweaked to visually match the shared Figma shot.
class WLTokens {
  // Layout
  static const double hPad = 20;        // screen horizontal padding
  static const double chipGap = 10;     // space between filter chips
  static const double cardHeight = 60;  // list item height
  static const double cardRadius = 7;  // list item radius

  // Colors (from screenshot)
  static const Color bg = Color(0xFFFAF9F7);
  static const Color appbarDivider = Color(0xFFEDEDED);
  static const Color title = Color(0xFF0F0F0F);
  static const Color textPrimary = Color(0xFF0F0F0F);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color addBrown = Color(0xFF7B4F1D); // "+ Add watchlist"
  static const Color chipBorder = Color(0xFFD9D9D9);
  static const Color chipFillSelected = Color(0xFFF3F3F3);
  static const Color outlineBlue = Color(0xFF2B7BFF);

  // Shadows
  static const List<BoxShadow> cardShadowFirst = [
    // soft lift like screenshot (first card only)
    BoxShadow(color: Color(0x29000000), offset: Offset(0, 8), blurRadius: 7, spreadRadius: 0),
  ];
  static const List<BoxShadow> cardShadowRest = []; // other cards no shadow

  // Typography (DM Sans intended)
  static const TextStyle appbarTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: title,
    height: 1.0,
  );

  static const TextStyle chipLabel = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF111111),
    height: 1.1,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.1,
  );

  static const TextStyle addAction = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.0,
  );

  static const TextStyle cardMeta = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle avatarText = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}




enum WatchlistCreateMode { smart, manual }



class WatchlistListPage extends StatefulWidget {
  const WatchlistListPage({super.key});

  @override
  State<WatchlistListPage> createState() => _WatchlistListPageState();
}


class _WatchlistListPageState extends State<WatchlistListPage> {
  final WatchlistService svc = GetIt.I<WatchlistService>();

  // render state only
  List<WatchlistSummary> _items = const [];
  bool _busy = false;
  String? _error;

  // ui state (filter chips) – matches screenshot: Watchlist selected
  int _chipIndex = 2; // 0: Screen, 1: Report, 2: Watchlist

  // subscriptions
  StreamSubscription<List<WatchlistSummary>>? _listSub;
  StreamSubscription<bool>? _busySub;
  StreamSubscription<String?>? _errSub;

  @override
  void initState() {
    super.initState();

    _listSub = svc.watchlistsStream.listen((list) {
      if (!mounted) return;
      setState(() => _items = list);
    });

    _busySub = svc.isBusyStream.listen((b) {
      if (!mounted) return;
      setState(() => _busy = b);
    });

    _errSub = svc.errorStream.listen((e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
      }
    });

    // safe initial pull (service may have bootstrapped already)
    // ignore: discarded_futures
    svc.refreshList();
  }

  @override
  void dispose() {
    _listSub?.cancel();
    _busySub?.cancel();
    _errSub?.cancel();
    super.dispose();
  }

  Future<WatchlistCreateMode?> _pickCreateMode(BuildContext context) {
    const brown = Color(0xFF7B4F1D);
    const titleStyle = TextStyle(
      fontFamily: 'DM Sans', fontWeight: FontWeight.w500, fontSize: 18, color: AppColors.black,
    );
    const itemTitle = TextStyle(
      fontFamily: 'DM Sans', fontWeight: FontWeight.w600, fontSize: 14, color:AppColors.black,
    );
    const itemSub = TextStyle(
      fontFamily: 'DM Sans', fontWeight: FontWeight.w400, fontSize: 12, color: Color(0xFF8C8C8C),
    );

    Widget _row({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // left icon box (matches screenshot proportions)
              SizedBox(
                width: 32, height: 32,
                child: Center(child: Icon(icon, size: 24, color: brown)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: itemTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: itemSub),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return showModalBottomSheet<WatchlistCreateMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // grabber
              Center(
                child: Container(
                  width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12, borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
               Text('Create your watchlist', style: titleStyle),
              const SizedBox(height: 18),

              _row(
                icon: Icons.chat_bubble_outline, // speech bubble
                title: 'Smart watchlist',
                subtitle: 'Chat with AI to create a watchlist',
                onTap: () => Navigator.of(ctx).pop(WatchlistCreateMode.smart),
              ),
              const SizedBox(height: 10),
              _row(
                icon: Icons.bookmark_border, // bookmark outline
                title: 'Manually',
                subtitle: 'Select and add stocks of your choice',
                onTap: () => Navigator.of(ctx).pop(WatchlistCreateMode.manual),
              ),
            ],
          ),
        );
      },
    );
  }



  void _openWatchlistDetailSheet(String watchlistId) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockSheet = BottomSheetManager.buildWachlistDetailSheet(
        watchlistid: watchlistId,
        onTap: () => _sheetKey.currentState?.closeSheet(),
      );
      _sheetKey.currentState?.openSheet(stockSheet);
    });
  }

  Future<void> _onEdit(WatchlistSummary wl) async {
    final c = TextEditingController(text: wl.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename watchlist'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await svc.editWatchlist(id: wl.id, name: name);
  }

  Future<void> _onDelete(WatchlistSummary wl) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete watchlist?'),
        content: Text('“${wl.name}” will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await svc.removeWatchlist(wl.id);
    }
  }

  Future<void> _openCreateWatchlistSheet() async {
    // 1) show mode picker first
    final mode = await _pickCreateMode(context);
    if (!mounted || mode == null) return;

    if (mode == WatchlistCreateMode.smart) {
      // TODO: open your AI chat flow
      // Example placeholder:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Smart watchlist coming soon')),
      );
      return;
    }

    // 2) If manual -> open the existing create-name sheet
    final created = await showModalBottomSheet<WatchlistDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CreateWatchlistSheet(service: svc),
    );

    if (!mounted) return;
    if (created != null) {
      // 3) Go to stock search to add symbols into the just-created watchlist
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StockSearchScreen(watchlistId: created.id),
        ),
      );
    }
  }

  final GlobalKey<ChatGPTBottomSheetWrapperState> _sheetKey =
  GlobalKey(debugLabel: 'BottomSheetWrapper');

  void _openSettingsSheet() {
    final settingsSheet = BottomSheetManager.buildSettingsSheet(
      onTap: () => _sheetKey.currentState?.closeSheet(),
    );
    _sheetKey.currentState?.openSheet(settingsSheet);
  }


  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double sidePad = media.size.width >= 600 ? WLTokens.hPad + 12 : WLTokens.hPad;

    return ChatGPTBottomSheetWrapper(
      key: _sheetKey,
      child: Scaffold(
        backgroundColor: WLTokens.bg,
        drawer: CustomDrawer(
          onTap: _openSettingsSheet,
          selectedRoute: "Watchlist",
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Builder(
            builder: (context) {
              return appBar(
                context,
                "Watchlist",
                    () {

                },
                false,
                showNewChatButton: false,
              );
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePad),
              child: Row(
                children: [
               _items.length == 0 ? SizedBox.shrink():   Text('${_items.length} Watchlists', style: WLTokens.sectionTitle),
                  const Spacer(),
                  InkWell(
                    onTap: _busy ? null : _openCreateWatchlistSheet,  // ⬅️ changed
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: WLTokens.addBrown),
                          SizedBox(width: 4),
                          Text('Add watchlist', style: WLTokens.addAction),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: _items.isEmpty
                    ? const Center(child: Text('No watchlists'))
                    : // at top of file:
              ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final it = _items[i];
                final bool elevated = i == 0;
                final bool outlined = i > 0;

                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 16 : 14),
                  child: _WatchlistCard(
                    item: it,
                    elevated: elevated,
                    outlined: outlined,
                    onTap: () async {

                      _openWatchlistDetailSheet(it.id);

                    },
                    onEdit: () => _onEdit(it),
                    onDelete: () => _onDelete(it),
                  ),
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

/// Center title with a tiny rounded square on the left + hairline divider (shadow).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.sidePad});

  final double sidePad;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          // hairline divider
          BoxShadow(color: WLTokens.appbarDivider, blurRadius: 0, spreadRadius: 0, offset: Offset(0, 1)),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: sidePad - 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const Center(child: Text('Watchlist', style: WLTokens.appbarTitle)),
          ],
        ),
      ),
    );
  }
}





class _WatchlistCard extends StatelessWidget {
  const _WatchlistCard({
    required this.item,
    required this.elevated,
    required this.outlined,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final WatchlistSummary item;
  final bool elevated;
  final bool outlined;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final deco = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(WLTokens.cardRadius),
      boxShadow: elevated ? WLTokens.cardShadowFirst : WLTokens.cardShadowRest,
      border: outlined ? Border.all(color: WLTokens.outlineBlue, width: 2) : null,
    );

    return Material(
      color: theme.background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WLTokens.cardRadius),
        child: Container(
          height: WLTokens.cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: deco,
          child: Row(
            children: [
              // Avatar (44px)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8D6E63), // brownish; swap per item if needed
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(item.name),
                  style: WLTokens.avatarText,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WLTokens.cardTitle,
                ),
              ),

              Text('${item.stocksCount} stocks', style: WLTokens.cardMeta),
              //const SizedBox(width: 10),

              // PopupMenuButton<String>(
              //   onSelected: (v) {
              //     if (v == 'rename') onEdit();
              //     if (v == 'delete') onDelete();
              //   },
              //   itemBuilder: (_) => const [
              //     PopupMenuItem(value: 'rename', child: Text('Rename')),
              //     PopupMenuItem(value: 'delete', child: Text('Delete')),
              //   ],
              //   icon: const Icon(Icons.arrow_forward_ios, size: 22, color: Color(0xFF111111)),
              // ),
              Icon(Icons.arrow_forward_ios, size: 22, color: Color(0xFF111111)),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts[0].isEmpty ? '' : parts[0][0]) +
        (parts[1].isEmpty ? '' : parts[1][0]).toUpperCase();
  }
}


class CreateWatchlistSheet extends StatefulWidget {
  const CreateWatchlistSheet({super.key, required this.service});
  final WatchlistService service;

  @override
  State<CreateWatchlistSheet> createState() => _CreateWatchlistSheetState();
}

class _CreateWatchlistSheetState extends State<CreateWatchlistSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final created = await widget.service.createWatchlist(name);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (created == null) {
      // Service surfaced error via its stream already; show local message too if needed
      setState(() => _error = 'Could not create watchlist');
      return;
    }

    Navigator.of(context).pop(created); // return the created detail to caller
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Create watchlist',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Enter name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          const SizedBox(height: 12),

          // SizedBox(
          //   width: double.infinity,
          //   height: 48,
          //   child: FilledButton(
          //     onPressed: _submitting ? null : _submit,
          //     child: _submitting
          //         ? const SizedBox(
          //       width: 20,
          //       height: 20,
          //       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          //     )
          //         : const Text(
          //       'Continue',
          //       style: TextStyle(
          //         fontFamily: 'DM Sans',
          //         fontWeight: FontWeight.w700,
          //         fontSize: 16,
          //       ),
          //     ),
          //   ),
          // ),
          CommonButton(
            label: "Continue",
            onPressed: _submitting ? null : _submit,
          )
        ],
      ),
    );
  }
}
