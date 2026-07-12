import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'direct_chat_service.dart';
import 'event_chat_service.dart';
import 'event_notes_service.dart';
import 'localization.dart';

class MessagesScreen extends StatefulWidget {
  final AppStrings strings;

  const MessagesScreen({super.key, required this.strings});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final DirectChatService _directChatService = DirectChatService();
  final EventChatService _eventChatService = EventChatService();
  final EventNotesService _eventNotesService = EventNotesService();

  late TabController _tabController;

  String _userId = '';
  String _userName = '';
  bool _loading = true;

  AppStrings get loc => widget.strings;

  String _tr({required String es, String? en, String? pt, String? it}) {
    switch (loc.language) {
      case AppLanguage.english:
        return en ?? es;
      case AppLanguage.portuguese:
        return pt ?? es;
      case AppLanguage.italian:
        return it ?? es;
      case AppLanguage.chinese:
      case AppLanguage.japanese:
      case AppLanguage.spanish:
        return es;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserContext();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final userName = (prefs.getString('profile_nombre') ?? '').trim();

    if (!mounted) return;
    setState(() {
      _userId = userId;
      _userName = userName.isEmpty ? loc.usuario : userName;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tr(
            es: 'Mensajes',
            en: 'Messages',
            pt: 'Mensagens',
            it: 'Messaggi',
          ),
        ),
        backgroundColor: const Color(0xFF0EA5A4),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.people_outline),
              text: _tr(es: 'Amigos', en: 'Friends', pt: 'Amigos', it: 'Amici'),
            ),
            Tab(
              icon: const Icon(Icons.event_note_outlined),
              text: _tr(es: 'Eventos', en: 'Events', pt: 'Eventos', it: 'Eventi'),
            ),
            Tab(
              icon: const Icon(Icons.sticky_note_2_outlined),
              text: _tr(es: 'Notas', en: 'Notes', pt: 'Notas', it: 'Note'),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userId.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _tr(
                        es: 'No se pudo identificar el usuario local.',
                        en: 'Could not identify local user.',
                        pt: 'Nao foi possivel identificar o usuario local.',
                        it: 'Impossibile identificare l\'utente locale.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDirectChatsTab(),
                    _buildEventChatsTab(),
                    _buildEventNotesTab(),
                  ],
                ),
    );
  }

  Widget _buildDirectChatsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _directChatService.streamChatsForUser(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _emptyState(
            title: _tr(
              es: 'Todavia no tienes chats con amigos',
              en: 'You do not have friend chats yet',
              pt: 'Voce ainda nao tem chats com amigos',
              it: 'Non hai ancora chat con amici',
            ),
            subtitle: _tr(
              es: 'Cuando inicies una conversacion, aparecera aqui.',
              en: 'When you start a conversation, it will appear here.',
              pt: 'Quando iniciar uma conversa, ela aparecera aqui.',
              it: 'Quando avvii una conversazione, apparira qui.',
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final chatId = docs[index].id;
            final names = Map<String, dynamic>.from(data['participantNames'] ?? const {});
            final participants = List<String>.from(data['participants'] ?? const <String>[]);
            final otherUserId = participants.firstWhere((id) => id != _userId, orElse: () => '');
            final otherName = (names[otherUserId] ?? _tr(es: 'Amigo', en: 'Friend', pt: 'Amigo', it: 'Amico')).toString();
            final lastMessageText = (data['lastMessageText'] ?? '').toString();

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0EA5A4).withOpacity(0.15),
                child: Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Color(0xFF0EA5A4), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                lastMessageText.isEmpty
                    ? _tr(es: 'Sin mensajes aun', en: 'No messages yet', pt: 'Sem mensagens ainda', it: 'Nessun messaggio')
                    : lastMessageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DirectChatThreadScreen(
                      strings: loc,
                      chatId: chatId,
                      currentUserId: _userId,
                      title: otherName,
                      service: _directChatService,
                    ),
                  ),
                );
              },
              trailing: _buildUnreadBadge(
                data: data,
                currentUserId: _userId,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventChatsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _eventChatService.streamChatsForUser(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _emptyState(
            title: _tr(
              es: 'Todavia no hay chats de eventos',
              en: 'No event chats yet',
              pt: 'Ainda nao ha chats de eventos',
              it: 'Nessuna chat evento',
            ),
            subtitle: _tr(
              es: 'Al crear o unirte a eventos, podras conversar aqui.',
              en: 'When you create or join events, you can chat here.',
              pt: 'Ao criar ou entrar em eventos, voce podera conversar aqui.',
              it: 'Creando o partecipando a eventi potrai parlare qui.',
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final eventId = docs[index].id;
            final eventName = (data['eventName'] ?? eventId).toString();
            final lastMessageText = (data['lastMessageText'] ?? '').toString();

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1422C55E),
                child: Icon(Icons.groups, color: Color(0xFF22C55E)),
              ),
              title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                lastMessageText.isEmpty
                    ? _tr(es: 'Sin mensajes aun', en: 'No messages yet', pt: 'Sem mensagens ainda', it: 'Nessun messaggio')
                    : lastMessageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventChatThreadScreen(
                      strings: loc,
                      eventId: eventId,
                      eventName: eventName,
                      currentUserId: _userId,
                      service: _eventChatService,
                    ),
                  ),
                );
              },
              trailing: _buildUnreadBadge(
                data: data,
                currentUserId: _userId,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventNotesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _eventNotesService.streamThreadsForUser(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _emptyState(
            title: _tr(
              es: 'Todavia no hay notas de eventos',
              en: 'No event notes yet',
              pt: 'Ainda nao ha notas de eventos',
              it: 'Nessuna nota evento',
            ),
            subtitle: _tr(
              es: 'Las notas tipo blog apareceran aqui.',
              en: 'Blog-style notes will appear here.',
              pt: 'As notas estilo blog aparecerao aqui.',
              it: 'Le note in stile blog appariranno qui.',
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final eventId = docs[index].id;
            final eventName = (data['eventName'] ?? eventId).toString();

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x14F59E0B),
                child: Icon(Icons.sticky_note_2, color: Color(0xFFF59E0B)),
              ),
              title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _tr(
                  es: 'Ideas, acuerdos y mini bitacora del evento',
                  en: 'Ideas, agreements and mini event log',
                  pt: 'Ideias, acordos e mini diario do evento',
                  it: 'Idee, accordi e mini diario evento',
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventNotesThreadScreen(
                      strings: loc,
                      eventId: eventId,
                      eventName: eventName,
                      currentUserId: _userId,
                      service: _eventNotesService,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _emptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadBadge({
    required Map<String, dynamic> data,
    required String currentUserId,
  }) {
    final unreadRaw = data['unreadCountByUser'];
    int unreadCount = 0;
    if (unreadRaw is Map<String, dynamic>) {
      final raw = unreadRaw[currentUserId];
      if (raw is int) unreadCount = raw;
      if (raw is num) unreadCount = raw.toInt();
    }

    if (unreadCount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        unreadCount > 99 ? '99+' : '$unreadCount',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class DirectChatThreadScreen extends StatefulWidget {
  final AppStrings strings;
  final String chatId;
  final String currentUserId;
  final String title;
  final DirectChatService service;

  const DirectChatThreadScreen({
    super.key,
    required this.strings,
    required this.chatId,
    required this.currentUserId,
    required this.title,
    required this.service,
  });

  @override
  State<DirectChatThreadScreen> createState() => _DirectChatThreadScreenState();
}

class _DirectChatThreadScreenState extends State<DirectChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();

  AppStrings get loc => widget.strings;

  String _tr({required String es, String? en, String? pt, String? it}) {
    switch (loc.language) {
      case AppLanguage.english:
        return en ?? es;
      case AppLanguage.portuguese:
        return pt ?? es;
      case AppLanguage.italian:
        return it ?? es;
      case AppLanguage.chinese:
      case AppLanguage.japanese:
      case AppLanguage.spanish:
        return es;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.service.markChatAsRead(
      chatId: widget.chatId,
      userId: widget.currentUserId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    _messageController.clear();
    await widget.service.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.service.streamMessages(widget.chatId),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = (data['text'] ?? '').toString();
                    final isMe = (data['senderId'] ?? '') == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF0EA5A4) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _tr(
                          es: 'Escribe un mensaje',
                          en: 'Write a message',
                          pt: 'Escreva uma mensagem',
                          it: 'Scrivi un messaggio',
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Color(0xFF0EA5A4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventChatThreadScreen extends StatefulWidget {
  final AppStrings strings;
  final String eventId;
  final String eventName;
  final String currentUserId;
  final EventChatService service;

  const EventChatThreadScreen({
    super.key,
    required this.strings,
    required this.eventId,
    required this.eventName,
    required this.currentUserId,
    required this.service,
  });

  @override
  State<EventChatThreadScreen> createState() => _EventChatThreadScreenState();
}

class _EventChatThreadScreenState extends State<EventChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();

  AppStrings get loc => widget.strings;

  String _tr({required String es, String? en, String? pt, String? it}) {
    switch (loc.language) {
      case AppLanguage.english:
        return en ?? es;
      case AppLanguage.portuguese:
        return pt ?? es;
      case AppLanguage.italian:
        return it ?? es;
      case AppLanguage.chinese:
      case AppLanguage.japanese:
      case AppLanguage.spanish:
        return es;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.service.markEventChatAsRead(
      eventId: widget.eventId,
      userId: widget.currentUserId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    _messageController.clear();
    await widget.service.sendMessage(
      eventId: widget.eventId,
      senderId: widget.currentUserId,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.eventName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.service.streamMessages(widget.eventId),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = (data['text'] ?? '').toString();
                    final isMe = (data['senderId'] ?? '') == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _tr(
                          es: 'Escribe un mensaje al evento',
                          en: 'Write a message to the event',
                          pt: 'Escreva uma mensagem para o evento',
                          it: 'Scrivi un messaggio all\'evento',
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Color(0xFF22C55E)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventNotesThreadScreen extends StatefulWidget {
  final AppStrings strings;
  final String eventId;
  final String eventName;
  final String currentUserId;
  final EventNotesService service;
  final String? highlightPostId;

  const EventNotesThreadScreen({
    super.key,
    required this.strings,
    required this.eventId,
    required this.eventName,
    required this.currentUserId,
    required this.service,
    this.highlightPostId,
  });

  @override
  State<EventNotesThreadScreen> createState() => _EventNotesThreadScreenState();
}

class _EventNotesThreadScreenState extends State<EventNotesThreadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _highlightedPostId;

  AppStrings get loc => widget.strings;

  String _tr({required String es, String? en, String? pt, String? it}) {
    switch (loc.language) {
      case AppLanguage.english:
        return en ?? es;
      case AppLanguage.portuguese:
        return pt ?? es;
      case AppLanguage.italian:
        return it ?? es;
      case AppLanguage.chinese:
      case AppLanguage.japanese:
      case AppLanguage.spanish:
        return es;
    }
  }

  @override
  void initState() {
    super.initState();
    _highlightedPostId = widget.highlightPostId;

    if (_highlightedPostId != null && _highlightedPostId!.isNotEmpty) {
      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted) return;
        setState(() {
          _highlightedPostId = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _createNote() async {
    await widget.service.addPost(
      eventId: widget.eventId,
      authorId: widget.currentUserId,
      title: _titleController.text,
      body: _bodyController.text,
    );
    _titleController.clear();
    _bodyController.clear();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr(es: 'Nueva nota', en: 'New note', pt: 'Nova nota', it: 'Nuova nota')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _tr(es: 'Titulo', en: 'Title', pt: 'Titulo', it: 'Titolo'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: _tr(es: 'Contenido', en: 'Content', pt: 'Conteudo', it: 'Contenuto'),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr(es: 'Cancelar', en: 'Cancel', pt: 'Cancelar', it: 'Annulla')),
          ),
          ElevatedButton(
            onPressed: _createNote,
            child: Text(_tr(es: 'Guardar', en: 'Save', pt: 'Salvar', it: 'Salva')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog({
    required String postId,
    required String initialTitle,
    required String initialBody,
  }) async {
    _titleController.text = initialTitle;
    _bodyController.text = initialBody;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr(es: 'Editar nota', en: 'Edit note', pt: 'Editar nota', it: 'Modifica nota')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _tr(es: 'Titulo', en: 'Title', pt: 'Titulo', it: 'Titolo'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: _tr(es: 'Contenido', en: 'Content', pt: 'Conteudo', it: 'Contenuto'),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr(es: 'Cancelar', en: 'Cancel', pt: 'Cancelar', it: 'Annulla')),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.service.updatePost(
                eventId: widget.eventId,
                postId: postId,
                title: _titleController.text,
                body: _bodyController.text,
              );
              _titleController.clear();
              _bodyController.clear();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: Text(_tr(es: 'Guardar', en: 'Save', pt: 'Salvar', it: 'Salva')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventName),
        actions: [
          IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.service.streamPosts(widget.eventId),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                _tr(
                  es: 'Sin notas para este evento',
                  en: 'No notes for this event',
                  pt: 'Sem notas para este evento',
                  it: 'Nessuna nota per questo evento',
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final postId = docs[index].id;
              final title = (data['title'] ?? '').toString();
              final body = (data['body'] ?? '').toString();
              final pinned = (data['pinned'] ?? false) == true;
              final authorId = (data['authorId'] ?? '').toString();
              final isMine = authorId == widget.currentUserId;
              final isHighlighted = _highlightedPostId == postId;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0xFFF59E0B).withOpacity(0.16)
                      : Colors.transparent,
                  border: isHighlighted
                      ? const Border(
                          left: BorderSide(color: Color(0xFFF59E0B), width: 4),
                        )
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    pinned ? Icons.push_pin : Icons.sticky_note_2_outlined,
                    color: pinned ? const Color(0xFFF59E0B) : null,
                  ),
                  title: Text(title),
                  subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: isMine
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _showEditDialog(
                                postId: postId,
                                initialTitle: title,
                                initialBody: body,
                              );
                              return;
                            }

                            if (value == 'pin') {
                              await widget.service.togglePinned(
                                eventId: widget.eventId,
                                postId: postId,
                                pinned: !pinned,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(_tr(es: 'Editar', en: 'Edit', pt: 'Editar', it: 'Modifica')),
                            ),
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(
                                pinned
                                    ? _tr(es: 'Desfijar', en: 'Unpin', pt: 'Desafixar', it: 'Rimuovi pin')
                                    : _tr(es: 'Fijar', en: 'Pin', pt: 'Fixar', it: 'Fissa'),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.note_add),
        label: Text(_tr(es: 'Nueva nota', en: 'New note', pt: 'Nova nota', it: 'Nuova nota')),
      ),
    );
  }
}
