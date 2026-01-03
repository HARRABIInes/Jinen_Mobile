import 'package:flutter/material.dart';
import '../services/notification_service_web.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      print('📬 Loading notifications for user: ${widget.userId}');
      final notifications = await NotificationServiceWeb.getNotifications(widget.userId);
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await NotificationServiceWeb.markAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationServiceWeb.deleteNotification(notificationId);
      _loadNotifications();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationServiceWeb.markAllAsRead(widget.userId);
      _loadNotifications();
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return '💬';
      case 'payment':
        return '💳';
      case 'enrollment_approved':
        return '✅';
      case 'enrollment_rejected':
        return '❌';
      case 'enrollment_cancelled':
        return '❌';
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF6C5CE7),
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tout marquer comme lu',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: const Color(0xFF6C5CE7),
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none_outlined,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Aucune notification',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final isRead = notification['isRead'] ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isRead ? 0 : 2,
                          color: isRead ? Colors.grey[100] : Colors.white,
                          child: InkWell(
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(notification['id']);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getNotificationIcon(notification['type'] ?? ''),
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notification['title'] ?? 'Notification',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                  decoration: isRead
                                                      ? TextDecoration.none
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF6C5CE7),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          notification['message'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          notification['sentAt'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      _deleteNotification(notification['id']);
                                    },
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
