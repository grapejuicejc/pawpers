import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/post.dart';
import '../../app_theme.dart';

class Comments extends StatefulWidget {
  final String postId;

  // If the user came from Profile > Comments,
  // this tells us which specific comment to highlight.
  final String? highlightCommentId;


  const Comments({super.key, required this.postId, this.highlightCommentId});

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  final _commentController = TextEditingController();

  List<PostComment> _comments = [];

  bool _isLoading = true;
  bool _isSending = false;

  // Keeps track of which comment is currently highlighted.
  String? _highlightedCommentId;
  PostComment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  // ---------------------------------------------------------------------------
  // FETCH COMMENTS
  // ---------------------------------------------------------------------------

  Future<void> _fetchComments() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('PostComments')
          .select('''
            commentID,
            postID,
            userID,
            comment,
            created_at,
            parentCommentId,

            profiles (
              username,
              profilePhotoUrl,
              is_verified
            )
          ''')
          .eq('postID', widget.postId)
          .order('created_at', ascending: true);

      final comments =
          data.map<PostComment>((row) {
            final profile = row['profiles'];

            return PostComment(
              id: row['commentID'].toString(),
              postId: row['postID'].toString(),
              authorId: row['userID'].toString(),
              parentCommentId: row['parentCommentId']?.toString(),

              authorName:
                  profile != null
                      ? profile['username']?.toString() ?? 'Unknown User'
                      : 'Unknown User',

              authorAvatarUrl:
                  profile != null
                      ? profile['profilePhotoUrl']?.toString()
                      : null,

              isVerified:
                  profile != null
                      ? (profile['is_verified'] as bool? ?? false)
                      : false,

              body: row['comment']?.toString() ?? '',

              repliedToCaptionPreview:
                  row['Post'] != null
                      ? row['Post']['caption']?.toString() ?? ''
                      : '',

              createdAt: DateTime.parse(row['created_at'].toString()),
            );
          }).toList();

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _isLoading = false;
      });

      // ---------------------------------------------------------------
      // HIGHLIGHT COMMENT
      // ---------------------------------------------------------------
      //
      // If we arrived here from:
      //
      // Profile > Comments > tap comment
      //
      // widget.highlightCommentId will contain that comment's ID.
      //
      if (widget.highlightCommentId != null) {
        _highlightComment();
      }
    } catch (e) {
      print('Error fetching comments: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load comments: $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // HIGHLIGHT + FADE
  // ---------------------------------------------------------------------------

  void _highlightComment() {
    final commentId = widget.highlightCommentId;

    if (commentId == null) return;

    // Make sure the comment actually exists.
    final exists = _comments.any((comment) => comment.id == commentId);

    if (!exists) return;

    // Wait until the comments ListView has been rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _highlightedCommentId = commentId;
      });

      // Keep the highlight visible for about 1.5 seconds.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        setState(() {
          _highlightedCommentId = null;
        });
      });
    });
  }

  // ---------------------------------------------------------------------------
  // ADD COMMENT
  // ---------------------------------------------------------------------------

  Future<void> _addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment.')),
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final insertData = {
        'postID': widget.postId,
        'userID': user.id,
        'comment': text,
      };

      // IF REPLYING TO A COMMENT

      if (_replyingTo != null) {
        insertData['parentCommentId'] = _replyingTo!.id;
      }

      // ---------------------------------------------------------------
      // INSERT INTO SUPABASE
      // ---------------------------------------------------------------

      await Supabase.instance.client.from('PostComments').insert(insertData);

      // ---------------------------------------------------------------
      // CLEAR INPUT
      // ---------------------------------------------------------------

      _commentController.clear();

      setState(() {
        _replyingTo = null;
      });

      // ---------------------------------------------------------------
      // REFRESH COMMENTS
      // ---------------------------------------------------------------

      await _fetchComments();
    } catch (e) {
      print('Error adding comment: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Only top-level comments are displayed in the main list.
    // Replies will be displayed underneath their parent comment.
    final topLevelComments =
        _comments.where((comment) => comment.parentCommentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),

      body: Column(
        children: [
          // ===============================================================
          // COMMENTS LIST
          // ===============================================================
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : topLevelComments.isEmpty
                    ? const Center(
                      child: Text(
                        'No comments yet.\nBe the first to comment!',
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),

                      itemCount: topLevelComments.length,

                      separatorBuilder: (_, __) => const SizedBox(height: 16),

                      itemBuilder: (context, index) {
                        final comment = topLevelComments[index];

                        // Find all replies belonging to this comment.
                        final replies =
                            _comments
                                .where(
                                  (reply) =>
                                      reply.parentCommentId == comment.id,
                                )
                                .toList();

                        final isHighlighted =
                            comment.id == _highlightedCommentId;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            // =================================================
                            // MAIN COMMENT
                            // =================================================
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),

                              curve: Curves.easeOut,

                              padding: const EdgeInsets.all(8),

                              decoration: BoxDecoration(
                                color:
                                    isHighlighted
                                        ? AppColors.accent.withOpacity(0.35)
                                        : Colors.transparent,

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  // -----------------------------------------
                                  // PROFILE PHOTO
                                  // -----------------------------------------
                                  CircleAvatar(
                                    radius: 18,

                                    backgroundColor: AppColors.placeholder,

                                    backgroundImage:
                                        comment.authorAvatarUrl != null &&
                                                comment
                                                    .authorAvatarUrl!
                                                    .isNotEmpty
                                            ? NetworkImage(
                                              comment.authorAvatarUrl!,
                                            )
                                            : null,

                                    child:
                                        comment.authorAvatarUrl == null ||
                                                comment.authorAvatarUrl!.isEmpty
                                            ? const Icon(
                                              Icons.person,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            )
                                            : null,
                                  ),

                                  const SizedBox(width: 10),

                                  // -----------------------------------------
                                  // COMMENT CONTENT
                                  // -----------------------------------------
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        // USERNAME
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                comment.authorName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                               if (comment.isVerified) ...[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.verified,
                                                  size: 13,
                                                  color: AppColors.primary,
                                                ),
                                              ],
                                            ],
                                          ),

                                        const SizedBox(height: 3),

                                        // COMMENT
                                        Text(
                                          comment.body,
                                          style: const TextStyle(fontSize: 14),
                                        ),

                                        const SizedBox(height: 4),

                                        // TIME + REPLY
                                        Row(
                                          children: [
                                            Text(
                                              formatCommentTime(
                                                comment.createdAt,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),

                                            const SizedBox(width: 16),

                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _replyingTo = comment;

                                                  _commentController.text =
                                                      '@${comment.authorName} ';

                                                  _commentController.selection =
                                                      TextSelection.fromPosition(
                                                        TextPosition(
                                                          offset:
                                                              _commentController
                                                                  .text
                                                                  .length,
                                                        ),
                                                      );
                                                });
                                              },

                                              child: const Text(
                                                'Reply',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
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

                            // =================================================
                            // REPLIES
                            // =================================================
                            if (replies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 42,
                                  top: 6,
                                ),

                                child: Column(
                                  children:
                                      replies.map((reply) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),

                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              // ---------------------------------
                                              // REPLY PROFILE PHOTO
                                              // ---------------------------------
                                              CircleAvatar(
                                                radius: 16,

                                                backgroundColor:
                                                    AppColors.placeholder,

                                                backgroundImage:
                                                    reply.authorAvatarUrl !=
                                                                null &&
                                                            reply
                                                                .authorAvatarUrl!
                                                                .isNotEmpty
                                                        ? NetworkImage(
                                                          reply
                                                              .authorAvatarUrl!,
                                                        )
                                                        : null,

                                                child:
                                                    reply.authorAvatarUrl ==
                                                                null ||
                                                            reply
                                                                .authorAvatarUrl!
                                                                .isEmpty
                                                        ? const Icon(
                                                          Icons.person,
                                                          size: 16,
                                                          color:
                                                              AppColors
                                                                  .textSecondary,
                                                        )
                                                        : null,
                                              ),

                                              const SizedBox(width: 8),

                                              // ---------------------------------
                                              // REPLY CONTENT
                                              // ---------------------------------
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,

                                                  children: [
                                                    // REPLY USERNAME
                                                     Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            comment.authorName,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (comment.isVerified) ...[
                                                          const SizedBox(width: 4),
                                                          const Icon(
                                                            Icons.verified,
                                                            size: 13,
                                                            color: AppColors.primary,
                                                          ),
                                                        ],
                                                      ],
                                                    ),

                                                    const SizedBox(height: 2),

                                                    // REPLY TEXT
                                                    Text(
                                                      reply.body,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 3),

                                                    // REPLY TIME + REPLY BUTTON
                                                    Row(
                                                      children: [
                                                        Text(
                                                          formatCommentTime(
                                                            reply.createdAt,
                                                          ),
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                AppColors
                                                                    .textSecondary,
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                          width: 14,
                                                        ),

                                                        GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _replyingTo =
                                                                  reply;

                                                              _commentController
                                                                      .text =
                                                                  '@${reply.authorName} ';

                                                              _commentController
                                                                  .selection = TextSelection.fromPosition(
                                                                TextPosition(
                                                                  offset:
                                                                      _commentController
                                                                          .text
                                                                          .length,
                                                                ),
                                                              );
                                                            });
                                                          },

                                                          child: const Text(
                                                            'Reply',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  AppColors
                                                                      .primary,
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
                                        );
                                      }).toList(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
          ),

          // ===============================================================
          // COMMENT / REPLY INPUT
          // ===============================================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // =========================================================
                  // REPLYING TO INDICATOR
                  // =========================================================
                  if (_replyingTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),

                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to @${_replyingTo!.authorName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyingTo = null;
                                _commentController.clear();
                              });
                            },

                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // =========================================================
                  // TEXT INPUT
                  // =========================================================
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,

                          textInputAction: TextInputAction.send,

                          onSubmitted: (_) {
                            if (!_isSending) {
                              _addComment();
                            }
                          },

                          decoration: InputDecoration(
                            hintText:
                                _replyingTo != null
                                    ? 'Write a reply...'
                                    : 'Write a comment...',

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        onPressed: _isSending ? null : _addComment,

                        icon:
                            _isSending
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,

                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.send,
                                  color: AppColors.primary,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// =============================================================================
// COMMENT TIME FORMATTER
// =============================================================================

String formatCommentTime(DateTime createdAt) {
  // Supabase stores timestamps in UTC.
  //
  // Convert both the comment time and current time
  // to Malaysia time (UTC+8) before comparing them.

  final malaysiaTime = createdAt.toUtc().add(const Duration(hours: 8));

  final now = DateTime.now().toUtc().add(const Duration(hours: 8));

  final difference = now.difference(malaysiaTime);

  // ---------------------------------------------------------------
  // LESS THAN 1 MINUTE
  // ---------------------------------------------------------------

  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  // ---------------------------------------------------------------
  // LESS THAN 1 HOUR
  // ---------------------------------------------------------------

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }

  // ---------------------------------------------------------------
  // LESS THAN 24 HOURS
  // ---------------------------------------------------------------

  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }

  // ---------------------------------------------------------------
  // LESS THAN 7 DAYS
  // ---------------------------------------------------------------

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  // ---------------------------------------------------------------
  // SAME YEAR
  // ---------------------------------------------------------------

  if (malaysiaTime.year == now.year) {
    return '${malaysiaTime.day} '
        '${_monthName(malaysiaTime.month)}';
  }

  // ---------------------------------------------------------------
  // DIFFERENT YEAR
  // ---------------------------------------------------------------

  return '${malaysiaTime.day} '
      '${_monthName(malaysiaTime.month)} '
      '${malaysiaTime.year}';
}

// =============================================================================
// MONTH NAME
// =============================================================================

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}
