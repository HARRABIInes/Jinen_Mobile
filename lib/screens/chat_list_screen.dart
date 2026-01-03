import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/conversation_service_web.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String userId;
  final String userType; // 'parent' ou 'directeur'
  final String? targetNurseryId; // Pour créer une conversation avec une garderie
  final String? targetParentId; // Pour nursery owner contacting parent

  const ChatListScreen({
    super.key,
    required this.userId,
    required this.userType,
    this.targetNurseryId,
    this.targetParentId,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If we're trying to start a conversation with a specific nursery/parent
    if (widget.targetNurseryId != null || widget.targetParentId != null) {
      _startNewConversation();
    } else {
      _chargerConversations();
    }
  }

  Future<void> _startNewConversation() async {
    try {
      if (widget.userType == 'parent' && widget.targetNurseryId != null) {
        // Parent contacting nursery
        print('💬 Parent creating conversation with nursery: ${widget.targetNurseryId}');
        
        final conversation = await ConversationServiceWeb.getOrCreateConversation(
          parentId: widget.userId,
          nurseryId: widget.targetNurseryId!,
        );

        if (conversation != null && mounted) {
          print('✅ Conversation created/fetched: ${conversation['id']}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversation['id'],
                userId: widget.userId,
                autreUtilisateurNom: conversation['nurseryName'] ?? 'Garderie',
              ),
            ),
          );
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Impossible de créer une conversation';
              _isLoading = false;
            });
          }
        }
      } else if (widget.userType == 'directeur' && widget.targetNurseryId != null && widget.targetParentId != null) {
        // Nursery owner contacting parent - use existing conversation or navigate to list
        print('💬 Nursery owner contacting parent: ${widget.targetParentId}');
        
        final conversation = await ConversationServiceWeb.getOrCreateConversation(
          parentId: widget.targetParentId!,
          nurseryId: widget.targetNurseryId!,
        );

        if (conversation != null && mounted) {
          print('✅ Conversation created/fetched: ${conversation['id']}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversation['id'],
                userId: widget.userId,
                autreUtilisateurNom: conversation['parentName'] ?? 'Parent',
              ),
            ),
          );
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Impossible de créer une conversation';
              _isLoading = false;
            });
          }
        }
      } else {
        // Just load conversations
        _chargerConversations();
      }
    } catch (e) {
      print('❌ Error starting conversation: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _chargerConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final conversations = await ConversationServiceWeb.getConversations(widget.userId);
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des conversations: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des conversations';
          _isLoading = false;
        });
      }
    }
  }

  String _getAutreUtilisateurNom(dynamic conversation) {
    if (widget.userType == 'parent') {
      return conversation['nurseryName'] ?? 'Directeur - Garderie';
    } else {
      return conversation['parentName'] ?? 'Parent';
    }
  }

  String _formatTemps(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _chargerConversations,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        return _buildConversationTile(conversation);
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userType == 'parent'
                ? 'Commencez une conversation avec une garderie'
                : 'Les parents peuvent vous contacter ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (widget.userType == 'parent')
            ElevatedButton.icon(
              onPressed: () => _showSelectNurseryDialog(),
              icon: const Icon(Icons.message),
              label: const Text('Contacter une garderie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showSelectNurseryDialog() async {
    // For now, show a simple message
    // In production, you'd fetch nurseries and show a list
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter une garderie'),
        content: const Text(
          'Naviguez vers "Accueil" ou "Mes Inscriptions" pour contacter une garderie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(dynamic conversation) {
    final lastMessage = conversation['lastMessage'] ?? 'Nouvelle conversation';
    final hasUnread = (conversation['unreadCount'] ?? 0) > 0;
    final lastMessageTime = conversation['lastMessageAt'] != null
        ? DateTime.parse(conversation['lastMessageAt'])
        : DateTime.now();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation['id'],
              userId: widget.userId,
              autreUtilisateurNom: _getAutreUtilisateurNom(conversation),
            ),
          ),
        ).then((_) => _chargerConversations());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
          color: hasUnread ? const Color(0xFF667EEA).withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF667EEA),
              child: Text(
                _getAutreUtilisateurNom(conversation)[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getAutreUtilisateurNom(conversation),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              hasUnread ? FontWeight.bold : FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        _formatTemps(lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? const Color(0xFF667EEA)
                              : Colors.grey[600],
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? const Color(0xFF374151)
                                : Colors.grey[600],
                            fontWeight:
                                hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${conversation['unreadCount']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
