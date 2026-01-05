const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { createNotification } = require('../utils/helpers');

// Get or create conversation between parent and nursery
router.post('/get-or-create', async (req, res) => {
  const { parentId, nurseryId } = req.body;

  if (!parentId || !nurseryId) {
    return res.status(400).json({ 
      success: false, 
      error: 'parentId and nurseryId are required' 
    });
  }

  try {
    // Check if conversation already exists
    const checkQuery = `
      SELECT c.id, c.parent_id, c.nursery_id, n.name as nursery_name, p.name as parent_name
      FROM conversations c
      LEFT JOIN nurseries n ON c.nursery_id = n.id
      LEFT JOIN users p ON c.parent_id = p.id
      WHERE c.parent_id = $1 AND c.nursery_id = $2
    `;
    const checkResult = await pool.query(checkQuery, [parentId, nurseryId]);

    if (checkResult.rows.length > 0) {
      const conversation = checkResult.rows[0];
      return res.json({
        success: true,
        conversation: {
          id: conversation.id,
          parentId: conversation.parent_id,
          nurseryId: conversation.nursery_id,
          parentName: conversation.parent_name,
          nurseryName: conversation.nursery_name
        }
      });
    }

    // Create new conversation and get nursery/parent info
    const insertQuery = `
      INSERT INTO conversations (parent_id, nursery_id, last_message_at)
      VALUES ($1, $2, CURRENT_TIMESTAMP)
      RETURNING id, parent_id, nursery_id
    `;
    const insertResult = await pool.query(insertQuery, [parentId, nurseryId]);
    const conversation = insertResult.rows[0];

    // Get nursery and parent names
    const infoQuery = `
      SELECT n.name as nursery_name, p.name as parent_name
      FROM nurseries n, users p
      WHERE n.id = $1 AND p.id = $2
    `;
    const infoResult = await pool.query(infoQuery, [nurseryId, parentId]);
    const info = infoResult.rows[0] || { nursery_name: null, parent_name: null };

    res.status(201).json({
      success: true,
      conversation: {
        id: conversation.id,
        parentId: conversation.parent_id,
        nurseryId: conversation.nursery_id,
        parentName: info.parent_name,
        nurseryName: info.nursery_name
      }
    });

  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to create conversation' 
    });
  }
});

// Get all conversations for a user
router.get('/user/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const query = `
      SELECT DISTINCT
        c.id,
        c.parent_id,
        c.nursery_id,
        c.last_message_at,
        p.name as parent_name,
        n.name as nursery_name,
        n.owner_id,
        u.name as owner_name,
        (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY sent_at DESC LIMIT 1) as last_message,
        COUNT(CASE WHEN m.is_read = false AND m.recipient_id = $1 THEN 1 END) as unread_count
      FROM conversations c
      LEFT JOIN users p ON c.parent_id = p.id
      LEFT JOIN nurseries n ON c.nursery_id = n.id
      LEFT JOIN users u ON n.owner_id = u.id
      LEFT JOIN messages m ON c.id = m.conversation_id
      WHERE c.parent_id = $1 OR n.owner_id = $1
      GROUP BY c.id, p.name, n.name, u.name, n.owner_id
      ORDER BY c.last_message_at DESC
    `;

    const result = await pool.query(query, [userId]);

    const conversations = result.rows.map(row => ({
      id: row.id,
      parentId: row.parent_id,
      parentName: row.parent_name,
      nurseryId: row.nursery_id,
      nurseryName: row.nursery_name,
      ownerId: row.owner_id,
      ownerName: row.owner_name,
      lastMessage: row.last_message || 'Nouvelle conversation',
      lastMessageAt: row.last_message_at,
      unreadCount: parseInt(row.unread_count) || 0
    }));

    res.json({
      success: true,
      conversations: conversations
    });

  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch conversations' 
    });
  }
});

// Get messages in a conversation
router.get('/:conversationId/messages', async (req, res) => {
  const { conversationId } = req.params;

  try {
    const query = `
      SELECT 
        m.id,
        m.sender_id,
        m.recipient_id,
        m.content,
        m.is_read,
        m.sent_at,
        u.name as sender_name
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.conversation_id = $1
      ORDER BY m.sent_at ASC
    `;

    const result = await pool.query(query, [conversationId]);

    const messages = result.rows.map(row => ({
      id: row.id,
      senderId: row.sender_id,
      senderName: row.sender_name,
      recipientId: row.recipient_id,
      content: row.content,
      isRead: row.is_read,
      sentAt: row.sent_at
    }));

    res.json({
      success: true,
      conversationId: conversationId,
      messages: messages
    });

  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch messages' 
    });
  }
});

// Send a message in a conversation
router.post('/:conversationId/messages', async (req, res) => {
  const { conversationId } = req.params;
  const { senderId, recipientId, content } = req.body;

  if (!senderId || !content) {
    return res.status(400).json({ 
      success: false, 
      error: 'senderId and content are required' 
    });
  }

  try {
    // Get conversation details to determine recipient
    let actualRecipientId = recipientId;
    
    if (!actualRecipientId) {
      // Fetch conversation to determine the other user
      const convQuery = `
        SELECT parent_id, nursery_id FROM conversations WHERE id = $1
      `;
      const convResult = await pool.query(convQuery, [conversationId]);
      
      if (convResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Conversation not found'
        });
      }
      
      const conversation = convResult.rows[0];
      
      // Determine recipient: if sender is parent, recipient is owner; otherwise vice versa
      const parentQuery = `
        SELECT owner_id FROM nurseries WHERE id = $1
      `;
      const parentResult = await pool.query(parentQuery, [conversation.nursery_id]);
      
      if (parentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Nursery not found'
        });
      }
      
      const nurseryOwnerId = parentResult.rows[0].owner_id;
      actualRecipientId = senderId === conversation.parent_id ? nurseryOwnerId : conversation.parent_id;
    }

    const query = `
      INSERT INTO messages (conversation_id, sender_id, recipient_id, content)
      VALUES ($1, $2, $3, $4)
      RETURNING id, sender_id, recipient_id, content, is_read, sent_at
    `;

    const result = await pool.query(query, [conversationId, senderId, actualRecipientId, content]);
    const message = result.rows[0];

    // Update conversation last_message_at
    await pool.query(
      'UPDATE conversations SET last_message_at = CURRENT_TIMESTAMP WHERE id = $1',
      [conversationId]
    );

    // Create notification for recipient (wrapped in try-catch so it doesn't fail the message sending)
    try {
      const senderQuery = `
        SELECT name FROM users WHERE id = $1
      `;
      const senderResult = await pool.query(senderQuery, [senderId]);
      const senderName = senderResult.rows[0]?.name || 'Quelqu\'un';

      const notificationQuery = `
        INSERT INTO notifications (user_id, title, message, type, related_id)
        VALUES ($1, $2, $3, $4, $5)
      `;
      await pool.query(notificationQuery, [
        actualRecipientId,
        `Nouveau message de ${senderName}`,
        `${senderName}: ${content.substring(0, 100)}${content.length > 100 ? '...' : ''}`,
        'message',
        conversationId
      ]);
      console.log('✅ Notification created for message');
    } catch (notificationError) {
      console.warn('⚠️ Could not create notification:', notificationError.message);
      // Don't fail the whole request if notification fails
    }

    res.status(201).json({
      success: true,
      message: {
        id: message.id,
        senderId: message.sender_id,
        recipientId: message.recipient_id,
        content: message.content,
        isRead: message.is_read,
        sentAt: message.sent_at
      }
    });

  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send message' 
    });
  }
});

// Mark messages as read
router.post('/:conversationId/mark-read', async (req, res) => {
  const { conversationId } = req.params;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ 
      success: false, 
      error: 'userId is required' 
    });
  }

  try {
    const query = `
      UPDATE messages
      SET is_read = true
      WHERE conversation_id = $1 AND recipient_id = $2 AND is_read = false
      RETURNING id
    `;

    await pool.query(query, [conversationId, userId]);

    res.json({
      success: true,
      message: 'Messages marked as read'
    });

  } catch (error) {
    console.error('Error marking messages as read:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to mark messages as read' 
    });
  }
});

module.exports = router;
