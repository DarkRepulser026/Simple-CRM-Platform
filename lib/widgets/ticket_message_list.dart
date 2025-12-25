import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_message.dart';

/// Widget for displaying a list of ticket messages with conversation thread styling
class TicketMessageList extends StatelessWidget {
  final List<TicketMessage> messages;
  final String? currentUserId;
  final bool showInternalNotes;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const TicketMessageList({
    super.key,
    required this.messages,
    this.currentUserId,
    this.showInternalNotes = true,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Filter messages based on visibility preferences
    final filteredMessages = messages.where((msg) {
      if (msg.isInternal && !showInternalNotes) {
        return false;
      }
      return true;
    }).toList();

    if (filteredMessages.isEmpty && !isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No messages yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredMessages.length,
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        final isCurrentUser = message.senderId == currentUserId;

        return TicketMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
        );
      },
    );
  }
}

/// Individual message bubble widget
class TicketMessageBubble extends StatelessWidget {
  final TicketMessage message;
  final bool isCurrentUser;

  const TicketMessageBubble({
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Color scheme for internal notes vs public replies
    final backgroundColor = message.isInternal
        ? cs.surfaceContainerLowest.withOpacity(0.6)
        : (isCurrentUser ? cs.primaryContainer : cs.surfaceContainerHigh);

    final textColor = message.isInternal
        ? cs.onSurfaceVariant
        : (isCurrentUser ? cs.onPrimaryContainer : cs.onSurface);

    final borderColor = message.isInternal
        ? cs.outlineVariant.withOpacity(0.5)
        : cs.outline.withOpacity(0.2);

    final formattedTime =
        DateFormat('MMM d, yyyy h:mm a').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message metadata row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isCurrentUser && message.senderName != null)
                  Text(
                    message.senderName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!isCurrentUser && message.senderName != null)
                  const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                if (message.isInternal) ...[
                  const SizedBox(width: 8),
                  const InternalNoteBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SelectableText(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge to indicate internal notes
class InternalNoteBadge extends StatelessWidget {
  const InternalNoteBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Internal',
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Timeline view for messages with visual timeline indicator
class TicketMessageTimeline extends StatelessWidget {
  final List<TicketMessage> messages;
  final String? currentUserId;

  const TicketMessageTimeline({
    super.key,
    required this.messages,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No conversation history',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final formattedTime =
            DateFormat('MMM d, yyyy h:mm a').format(message.createdAt);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: message.isInternal ? cs.error : cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index < messages.length - 1)
                    Container(
                      width: 2,
                      height: 60,
                      color: cs.outlineVariant.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (message.senderName != null)
                          Text(
                            message.senderName!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (message.senderName != null) const SizedBox(width: 8),
                        if (message.isInternal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Internal',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isInternal
                            ? cs.surfaceContainerLowest.withOpacity(0.6)
                            : cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: message.isInternal
                              ? cs.outlineVariant.withOpacity(0.5)
                              : cs.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: message.isInternal
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
