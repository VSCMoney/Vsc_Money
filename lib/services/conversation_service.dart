import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vscmoney/services/locator.dart';

import '../models/chat_session.dart';
import 'chat_service.dart';

class ConversationsService {
  final ChatService _chatService = locator<ChatService>();
  final BehaviorSubject<ConversationsState> _state = BehaviorSubject.seeded(ConversationsState.initial());
  final TextEditingController _searchController = TextEditingController();

  Stream<ConversationsState> get sessionsStream => _state.stream;
  ConversationsState get currentState => _state.value;

  ConversationsService() {
    _searchController.addListener(_onSearchChanged);
  }

  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _state.close();
  }

  Future<void> loadSessions() async {
    _state.add(currentState.copyWith(isLoading: true));

    try {
      final sessions = await _chatService.fetchSessions();
      _state.add(ConversationsState(
        allSessions: sessions,
        filteredSessions: sessions,
        groupedSessions: _groupByDate(sessions),
        isLoading: false,
      ));
    } catch (e) {
      _state.add(currentState.copyWith(isLoading: false));
      debugPrint("Error loading sessions: $e");
    }
  }

  // ChatSession? getSessionById(String? id) {
  //   if (id == null) return null;
  //   return _sessions.firstWhereOrNull((s) => s.id == id);
  // }

  ChatSession? getSessionById(String id) {
    try {
      return currentState.allSessions.firstWhere((session) => session.id == id);
    } catch (_) {
      return null;
    }
  }




  void searchSessions(String query) {
    if (query.isEmpty) {
      _state.add(currentState.copyWith(
        filteredSessions: currentState.allSessions,
        groupedSessions: _groupByDate(currentState.allSessions),
      ));
      return;
    }

    final filtered = currentState.allSessions.where(
          (session) => session.title.toLowerCase().contains(query.toLowerCase()),
    ).toList();

    _state.add(currentState.copyWith(
      filteredSessions: filtered,
      groupedSessions: _groupByDate(filtered),
    ));
  }

  void _onSearchChanged() {
    searchSessions(_searchController.text.trim());
  }

  Map<String, List<ChatSession>> _groupByDate(List<ChatSession> sessions) {
    final Map<String, List<ChatSession>> grouped = {};
    for (var session in sessions) {
      final dt = session.createdAt ?? DateTime.now();
      final label = _getLabelForDate(dt);
      grouped.putIfAbsent(label, () => []).add(session);
    }
    return grouped;
  }

  String _getLabelForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compare = DateTime(date.year, date.month, date.day);

    if (compare == today) return 'Today';
    if (compare == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (compare.isAfter(today.subtract(const Duration(days: 7)))) {
      final daysAgo = today.difference(compare).inDays;
      return '$daysAgo days ago';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class ConversationsState {
  final List<ChatSession> allSessions;
  final List<ChatSession> filteredSessions;
  final Map<String, List<ChatSession>> groupedSessions;
  final bool isLoading;

  const ConversationsState({
    required this.allSessions,
    required this.filteredSessions,
    required this.groupedSessions,
    required this.isLoading,
  });

  factory ConversationsState.initial() => ConversationsState(
    allSessions: [],
    filteredSessions: [],
    groupedSessions: {},
    isLoading: true,
  );

  ConversationsState copyWith({
    List<ChatSession>? allSessions,
    List<ChatSession>? filteredSessions,
    Map<String, List<ChatSession>>? groupedSessions,
    bool? isLoading,
  }) {
    return ConversationsState(
      allSessions: allSessions ?? this.allSessions,
      filteredSessions: filteredSessions ?? this.filteredSessions,
      groupedSessions: groupedSessions ?? this.groupedSessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}