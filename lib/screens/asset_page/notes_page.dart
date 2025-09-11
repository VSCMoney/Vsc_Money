import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:vscmoney/services/locator.dart';

import '../../models/notes_modal.dart';
import '../../services/file_service.dart';
import '../../services/notes_service.dart';
import '../../services/theme_service.dart';
import '../../services/voice_service.dart';
import '../widgets/voice_input_widget.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

// import your own types/services from where you put them:
/// e.g.
/// import 'package:your_app/services/notes_service.dart';
/// import 'package:your_app/services/file_service.dart';
/// import 'package:your_app/models/note.dart';
/// import 'package:your_app/models/note_attachment.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

// Import your services/models
// import 'package:your_app/services/notes_service.dart';
// import 'package:your_app/services/file_service.dart';
// import 'package:your_app/models/note.dart';
// import 'package:your_app/models/note_attachment.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

/// import your own services/models
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';


class NotesPage extends StatefulWidget {
  final Note? initialNote;
  const NotesPage({Key? key, this.initialNote}) : super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with TickerProviderStateMixin {
  // Single controller + focus
  final TextEditingController _controller = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  // Services
  final AudioService _audioService = AudioService.instance;
  final NotesService _notes = NotesService();
  final FileService _fileService = FileService();

  Note? _note; // becomes non-null after first manual Save
  final List<NoteAttachment> _attachments = [];

  // --- Transcription handling ---
  String _latestTranscript = '';
  TextSelection? _recordSelection;
  bool _pendingInsert = false;

  // ✅ NEW: snapshot of the editor when recording starts
  String _recordBaseline = '';

  // File op streams
  StreamSubscription<bool>? _processingSub;
  StreamSubscription<double>? _progressSub;
  StreamSubscription<String>? _fileErrSub;

  bool _isProcessingFiles = false;
  double _uploadProgress = 0.0;

  // Animations
  late AnimationController _heightController;
  late AnimationController _contentControllers;
  late Animation<double> _heightAnimation;
  late Animation<double> _actionBarOpacity;
  late Animation<double> _recorderOpacity;

  // Recording state
  bool _isRecording = false;
  bool _preparing = false;

  // Audio subs
  late StreamSubscription<bool> _isListeningSubscription;
  late StreamSubscription<String> _transcriptSubscription;
  late StreamSubscription<String> _errorSubscription;

  static const double _normalHeight = 60.0;
  static const double _recordingHeight = 60.0;
  static const Duration _toVoiceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    _notes.initialize();

    if (widget.initialNote != null) {
      _note = widget.initialNote;
      final pieces = <String>[];
      if (_note!.title.isNotEmpty) pieces.add(_note!.title);
      if (_note!.content.isNotEmpty) pieces.add(_note!.content);
      _controller.text = pieces.join('\n\n');
      _attachments.addAll(_note!.attachments);
    } else {
      _controller.clear();
      _attachments.clear();
    }

    _setupAnimations();
    _setupAudioSubscriptions();
    _setupFileSubscriptions();
  }

  // ---------- setup ----------

  void _setupFileSubscriptions() {
    _processingSub = _fileService.isProcessing$.listen((p) {
      if (!mounted) return;
      setState(() => _isProcessingFiles = p);
    });

    _progressSub = _fileService.uploadProgress$.listen((v) {
      if (!mounted) return;
      setState(() => _uploadProgress = v);
    });

    _fileErrSub = _fileService.error$.listen((msg) {
      if (!mounted || msg.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _fileService.clearError();
    });
  }

  void _setupAnimations() {
    _heightController = AnimationController(duration: _toVoiceDuration, vsync: this);
    _contentControllers = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _heightAnimation = Tween<double>(begin: _normalHeight, end: _recordingHeight)
        .animate(CurvedAnimation(parent: _heightController, curve: Curves.easeInOut));

    _actionBarOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentControllers, curve: Curves.easeOut, reverseCurve: Curves.easeIn),
    );

    _recorderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentControllers, curve: Curves.easeIn, reverseCurve: Curves.easeOut),
    );
  }

  void _setupAudioSubscriptions() {
    _isListeningSubscription = _audioService.isListening$.listen((listening) {
      if (!mounted) return;
      if (listening) {
        setState(() => _preparing = false);
      } else if (!_preparing) {
        _returnToNormal();
      }
    });

    // ✅ Sanitize transcript to only the NEW part (no previous text)
    _transcriptSubscription = _audioService.transcript$.listen((raw) {
      if (raw.isEmpty) return;
      _latestTranscript = _cleanTranscript(raw, _recordBaseline);
      if (_pendingInsert) _maybeInsertTranscript();
    });

    _errorSubscription = _audioService.error$.listen((error) {
      if (!mounted || error.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      _audioService.clearError();
      _returnToNormal();
    });
  }

  // ---------- recording ----------

  void _startRecordingTransition() {
    setState(() {
      _preparing = true;
      _isRecording = true;
    });
    _contentControllers.forward();
  }

  void _returnToNormal() {
    setState(() {
      _preparing = false;
      _isRecording = false;
    });
    _contentControllers.reverse();
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    _noteFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // snapshot caret for later insertion
    final sel = _controller.selection;
    _recordSelection = sel.isValid
        ? sel
        : TextSelection.collapsed(offset: _controller.text.length);

    _recordBaseline = _controller.text; // ✅ remember current text
    _latestTranscript = '';
    _pendingInsert = false;

    _startRecordingTransition();

    try {
      // If your backend echoes existingText back, consider passing '' here.
      await _audioService.startRecording(existingText: _controller.text);
    } catch (_) {
      if (mounted) _returnToNormal();
    }
  }

  void _onRecordingComplete() {
    _pendingInsert = true;
    _maybeInsertTranscript();
    _returnToNormal();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) FocusScope.of(context).requestFocus(_noteFocusNode);
    });
  }

  void _onRecordingCancel() {
    HapticFeedback.mediumImpact();
    _pendingInsert = false;
    _latestTranscript = '';
    _recordSelection = null;
    _recordBaseline = '';
    _returnToNormal();
  }

  void _maybeInsertTranscript() {
    var t = _cleanTranscript(_latestTranscript, _recordBaseline).trim();
    if (!_pendingInsert || t.isEmpty) return;

    final full = _controller.text;
    final start = (_recordSelection?.isValid ?? false) ? _recordSelection!.start : full.length;
    final end   = (_recordSelection?.isValid ?? false) ? _recordSelection!.end   : start;

    final before = full.substring(0, start);
    final after  = full.substring(end);

    final needsNL = before.isNotEmpty && !before.endsWith('\n');
    final sep = needsNL ? '\n' : '';

    final newText = '$before$sep$t$after';
    final newOffset = (before + sep + t).length;

    setState(() => _controller.text = newText);
    _controller.selection = TextSelection.collapsed(offset: newOffset);

    // cleanup
    _pendingInsert = false;
    _latestTranscript = '';
    _recordSelection = null;
    _recordBaseline = '';
  }

  // ---------- SAVE ----------

  Future<void> _saveNote() async {
    final raw = _controller.text.trim();

    String title = 'Untitled';
    String content = '';

    if (raw.isNotEmpty) {
      final idx = raw.indexOf('\n');
      if (idx == -1) {
        title = raw;
      } else {
        title = raw.substring(0, idx).trim();
        content = raw.substring(idx + 1).trim();
        if (title.isEmpty) title = 'Untitled';
      }
    }

    try {
      if (_note == null) {
        final created = await _notes.createNote(title: title, content: content);
        final updated = await _notes.updateNote(
          created.id,
          attachments: List<NoteAttachment>.from(_attachments),
        );
        setState(() => _note = updated);
      } else {
        final updated = await _notes.updateNote(
          _note!.id,
          title: title,
          content: content,
          attachments: List<NoteAttachment>.from(_attachments),
        );
        setState(() => _note = updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  // ---------- attachments ----------

  Future<void> _onAttachTap() async {
    HapticFeedback.selectionClick();

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _BottomSheetItem(icon: Icons.photo_camera_outlined, label: 'Camera', value: 'camera'),
              _BottomSheetItem(icon: Icons.photo_library_outlined, label: 'Gallery (Single)', value: 'gallery_single'),
              _BottomSheetItem(icon: Icons.description_outlined, label: 'Documents', value: 'docs'),
              _BottomSheetItem(icon: Icons.attach_file_outlined, label: 'Any file', value: 'any'),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    try {
      switch (choice) {
        case 'camera':
          final a1 = await _fileService.pickImageFromCamera();
          if (a1 != null) setState(() => _attachments.add(a1));
          break;
        case 'gallery_single':
          final a2 = await _fileService.pickImageFromGallery();
          if (a2 != null) setState(() => _attachments.add(a2));
          break;
        case 'gallery_multi':
          final list1 = await _fileService.pickMultipleImages();
          if (list1.isNotEmpty) setState(() => _attachments.addAll(list1));
          break;
        case 'docs':
          final list2 = await _fileService.pickDocuments();
          if (list2.isNotEmpty) setState(() => _attachments.addAll(list2));
          break;
        case 'any':
          final list3 = await _fileService.pickAnyFiles();
          if (list3.isNotEmpty) setState(() => _attachments.addAll(list3));
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to attach: $e')));
    }
  }

  Future<void> _removeAttachment(NoteAttachment a) async {
    try {
      await _fileService.deleteAttachment(a);
    } catch (_) {
      // ignore delete errors; still remove from UI
    } finally {
      if (!mounted) return;
      setState(() => _attachments.removeWhere((x) => x.id == a.id));
    }
  }

  // ---------- lifecycle ----------

  @override
  void dispose() {
    _processingSub?.cancel();
    _progressSub?.cancel();
    _fileErrSub?.cancel();

    _controller.dispose();
    _noteFocusNode.dispose();

    _isListeningSubscription.cancel();
    _transcriptSubscription.cancel();
    _errorSubscription.cancel();
    _heightController.dispose();
    _contentControllers.dispose();
    super.dispose();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final showRecorder = _preparing || _audioService.isListening;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Column(
          children: [
            _buildNotesAppBar(),
            if (_isProcessingFiles)
              LinearProgressIndicator(
                value: (_uploadProgress <= 0.0 || _uploadProgress >= 1.0) ? null : _uploadProgress,
                minHeight: 2,
              ),
            Expanded(
              child: Container(
              //  color: theme.background,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_attachments.isNotEmpty) ...[
                      _AttachmentsGrid(
                        attachments: _attachments,
                        onOpen: (a) => OpenFilex.open(a.path),
                        onRemove: _removeAttachment,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _noteFocusNode,
                        style:  TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: theme.text,
                          height: 1.5,
                        ),
                        decoration:  InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Write your note…',
                          hintStyle: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: theme.text,
                          ),
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom action bar
            AnimatedBuilder(
              animation: _heightAnimation,
              builder: (context, child) {
                return Container(
                  color: theme.background,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: SafeArea(
                    child: SizedBox(
                      height: _heightAnimation.value,
                      child: Stack(
                        children: [
                          // Normal pill (Record + Attach)
                          AnimatedBuilder(
                            animation: _contentControllers,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _actionBarOpacity.value,
                                child: IgnorePointer(
                                  ignoring: _actionBarOpacity.value < 0.1,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      height: 56,
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: theme.box,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _startRecording,
                                              behavior: HitTestBehavior.opaque,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children:  [
                                                  Padding(
                                                    padding: EdgeInsets.all(2.0),
                                                    child: Icon(Icons.graphic_eq,
                                                        color: theme.notes, size: 20),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Record Audio',
                                                    style: TextStyle(
                                                      fontFamily: 'DM Sans',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: theme.notes,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: double.infinity,
                                            child: VerticalDivider(
                                              width: 24,
                                              thickness: 1,
                                              color: const Color(0xFFE5E5E5),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _onAttachTap,
                                              behavior: HitTestBehavior.opaque,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children:  [
                                                  RotatedBox(
                                                    quarterTurns: 1,
                                                    child: Icon(Icons.attach_file,
                                                        color: theme.notes, size: 20),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Attach file',
                                                    style: TextStyle(
                                                      fontFamily: 'DM Sans',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: theme.notes,
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
                            },
                          ),
                          // Recorder widget
                          AnimatedBuilder(
                            animation: _contentControllers,
                            builder: (context, child) {
                              final showRecorder = _preparing || _audioService.isListening;
                              return Opacity(
                                opacity: _recorderOpacity.value,
                                child: IgnorePointer(
                                  ignoring: _recorderOpacity.value < 0.1,
                                  child: showRecorder
                                      ? VoiceRecorderWidget(
                                    audioService: _audioService,
                                    onCancel: _onRecordingCancel,
                                    onComplete: _onRecordingComplete,
                                  )
                                      : const SizedBox.shrink(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );




  }

  // ---------- Helpers to clean transcript ----------

  // Remove any part of `text` that matches the beginning of `baseline`.
  // Also tries a looser "normalized" removal and collapses duplicate adjacent sentences.
  String _cleanTranscript(String text, String baseline) {
    if (text.isEmpty) return text;

    String s = text;

    // 1) Exact longest common prefix (character-wise)
    final lcp = _longestCommonPrefix(baseline, s);
    if (lcp > 0) {
      s = s.substring(lcp);
    } else {
      // 2) Fallback: if backend echoed a big chunk of baseline somewhere at start, drop it once
      if (baseline.isNotEmpty && s.startsWith(baseline)) {
        s = s.substring(baseline.length);
      } else if (baseline.length >= 40) {
        final tail = baseline.substring(baseline.length - 40);
        final idx = s.indexOf(tail);
        if (idx == 0) s = s.substring(tail.length);
      }
    }

    // 3) Trim leading whitespace/punctuation bullets
    s = s.replaceFirst(RegExp(r'^[\s\n\r\-–—•·:]+'), '');

    // 4) Deduplicate adjacent sentences/lines if ASR repeated them
    s = _dedupeAdjacent(s);

    return s.trim();
  }

  int _longestCommonPrefix(String a, String b) {
    final n = (a.length < b.length) ? a.length : b.length;
    var i = 0;
    while (i < n && a.codeUnitAt(i) == b.codeUnitAt(i)) {
      i++;
    }
    return i;
    // If you want a whitespace-normalized LCP, you can add another pass.
  }

  String _dedupeAdjacent(String input) {
    // split by sentence-ish boundaries or double newlines
    final parts = input.split(RegExp(r'(\n{2,}|(?<=[.!?])\s+)'));
    final buf = StringBuffer();
    String? prev;
    for (final part in parts) {
      final token = part.trim();
      if (token.isEmpty) {
        buf.write(part);
        continue;
      }
      if (prev != null && token == prev) {
        // skip duplicate
        continue;
      }
      buf.write(part);
      prev = token;
    }
    return buf.toString();
  }


  Widget _buildNotesAppBar() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.box,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Left - Back button
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(Icons.arrow_back, color: theme.icon, size: 24),
              ),
            ),

            // Center - Title
            Expanded(
              child: Text(
                'Notes',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.text,
                  fontFamily: "DM Sans",
                ),
              ),
            ),

            // Right - Save button
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _saveNote,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4871A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _AttachmentsGrid extends StatelessWidget {
  final List<NoteAttachment> attachments;
  final void Function(NoteAttachment) onRemove;
  final void Function(NoteAttachment) onOpen;

  const _AttachmentsGrid({
    Key? key,
    required this.attachments,
    required this.onRemove,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: attachments
          .map((a) => Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => onOpen(a),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.insert_drive_file, color: Color(0xFF9E9E9E)),
            ),
          ),
          Positioned(
            right: -6,
            top: -6,
            child: GestureDetector(
              onTap: () => onRemove(a),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 16),
              ),
            ),
          ),
        ],
      ))
          .toList(),
    );
  }
}

class _BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _BottomSheetItem({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF333333)),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}


class _RecordingRow extends StatefulWidget {
  const _RecordingRow({
    Key? key,
    required this.onCancel,
    required this.onStop,
    required this.audioService,
  }) : super(key: key);

  final VoidCallback onCancel;
  final VoidCallback onStop;
  final AudioService audioService;

  @override
  State<_RecordingRow> createState() => _RecordingRowState();
}

class _RecordingRowState extends State<_RecordingRow> {
  static const _accent = Color(0xFFD4871A);
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.mic, color: _accent, size: 20),
        const SizedBox(width: 8),

        // "Recording…" + timer
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recording…',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _mmss(_elapsed),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),

        // Cancel
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onCancel,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
          ),
        ),
        const SizedBox(width: 6),

        // Stop (done)
        Container(
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onStop,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.stop, color: _accent, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Stop',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}






class NotesListPage extends StatefulWidget {
  const NotesListPage({Key? key}) : super(key: key);

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NotesService _notes = NotesService();
  final _dateFmt = DateFormat('d MMMM yy'); // e.g. 12 July 25

  @override
  void initState() {
    super.initState();
    _notes.initialize(); // loads from SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Column(
          children: [
            _buildNotesAppBar(),
            Expanded(
              child: StreamBuilder<List<Note>>(
                stream: _notes.notes$,
                builder: (context, snap) {
                  final items = (snap.data ?? const <Note>[]);
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notes yet',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final hasAtchs = n.attachments.isNotEmpty;
                      final dateStr = _dateFmt.format(n.updatedAt);

                      return Dismissible(
                        key: ValueKey('note-${n.id}'),
                        direction: DismissDirection.endToStart, // swipe left to delete
                        background: _buildSwipeBg(Alignment.centerLeft),           // optional (for startToEnd)
                        secondaryBackground: _buildSwipeBg(Alignment.centerRight), // shown for endToStart
                        confirmDismiss: (direction) => _confirmDelete(n),
                        onDismissed: (direction) async {
                          try {
                            await _notes.deleteNote(n.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Note deleted')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete note: $e')),
                              );
                              // Rebuild; the stream will re-emit items if delete failed.
                              setState(() {});
                            }
                          }
                        },
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => NotesPage(initialNote: n)),
                            );
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: theme.box,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          n.title.isEmpty ? 'Untitled' : n.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:  TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: theme.text,
                                          ),
                                        ),
                                      ),
                                      if (hasAtchs) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.attach_file, size: 16, color: Color(0xFF333333)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9AA0A6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemCount: items.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeBg(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
    );
  }

  Future<bool> _confirmDelete(Note n) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true, // avoids nested navigator issues
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: const Text('This will permanently delete the note and its attachments.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }


  Widget _buildNotesAppBar() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.box,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Left - Back button
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_back, color: theme.icon, size: 24),
                ),
              ),
            ),

            // Center - Title
            Expanded(
              child: Text(
                'Notes',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.text,
                  fontFamily: "DM Sans",
                ),
              ),
            ),

            // Right - Save button
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: ()async{
                  try {
                    // 1) create a new note immediately
                    final created = await _notes.createNote(title: '', content: '');

                    if (!mounted) return;

                    // 2) open the editor for that note
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NotesPage(initialNote: created)),
                    );

                    // 3) refresh list after returning
                    if (!mounted) return;
                    setState(() {});
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create note: $e')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4871A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesAppBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final String? actionLabel;
  final VoidCallback? onAction;

  // Control whether the bar inserts status-bar height
  final bool addTopInset;
  final Color pageBackground;
  final Color barColor;
  final Color dividerColor;

  const NotesAppBar({
    Key? key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actionLabel,
    this.onAction,
    this.addTopInset = true, // default behavior unchanged
    this.pageBackground = const Color(0xFFF5F5F5),
    this.barColor = Colors.white,
    this.dividerColor = const Color(0xFFE5E5E5),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (addTopInset) Container(height: topInset, color: pageBackground),
        Material(
          color: barColor,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8C5A00)),
                    onPressed: onBack,
                    tooltip: 'Back',
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
                if (actionLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD4871A),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        SizedBox(height: 1, child: ColoredBox(color: dividerColor)),
      ],
    );
  }
}




