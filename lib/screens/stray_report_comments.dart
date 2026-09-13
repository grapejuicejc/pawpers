import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import 'other_user_profile.dart';

class StrayReportCommentsScreen extends StatefulWidget {
  final String strayId;

  const StrayReportCommentsScreen({
    super.key,
    required this.strayId,
  });

  @override
  State<StrayReportCommentsScreen> createState() =>
      _StrayReportCommentsScreenState();
}

class _StrayReportCommentsScreenState
    extends State<StrayReportCommentsScreen> {

  final TextEditingController _commentController =
      TextEditingController();

  List<Map<String, dynamic>> _comments = [];

  bool _isLoading = true;
  bool _isSending = false;

  // The comment that the user is replying to.
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ============================================================
  // FETCH COMMENTS
  // ============================================================

  Future<void> _fetchComments() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('StrayReportComments')
          .select('''
            commentID,
            strayID,
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
          .eq('strayID', widget.strayId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        _comments =
            List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });

    } catch (e) {
      print('Error fetching stray comments: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load comments: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // START REPLY
  // ============================================================

  void _startReply(Map<String, dynamic> comment) {

    final profile = comment['profiles'];

    final username =
        profile?['username']?.toString() ??
        'Unknown User';

    setState(() {
      _replyingTo = comment;

      _commentController.text =
          '@$username ';

      _commentController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: _commentController.text.length,
        ),
      );
    });
  }

  // ============================================================
  // CANCEL REPLY
  // ============================================================

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _commentController.clear();
    });
  }

  // ============================================================
  // ADD COMMENT / REPLY
  // ============================================================

  Future<void> _addComment() async {

    final text =
        _commentController.text.trim();

    if (text.isEmpty) return;

    final supabase =
        Supabase.instance.client;

    final user =
        supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in to comment.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {

      final Map<String, dynamic> insertData = {
        'strayID': widget.strayId,
        'userID': user.id,
        'comment': text,
      };

      // ----------------------------------------------------------
      // IF THIS IS A REPLY
      // ----------------------------------------------------------

      if (_replyingTo != null) {

        insertData['parentCommentId'] =
            _replyingTo!['commentID'];
      }

      // ----------------------------------------------------------
      // INSERT
      // ----------------------------------------------------------

      await supabase
          .from('StrayReportComments')
          .insert(insertData);

      // ----------------------------------------------------------
      // CLEAR INPUT
      // ----------------------------------------------------------

      _commentController.clear();

      setState(() {
        _replyingTo = null;
      });

      // ----------------------------------------------------------
      // REFRESH
      // ----------------------------------------------------------

      await _fetchComments();

    } catch (e) {

      print(
        'Error adding stray comment: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add comment: $e',
          ),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    // ----------------------------------------------------------
    // ONLY TOP-LEVEL COMMENTS
    // ----------------------------------------------------------

    final topLevelComments =
        _comments.where((comment) {

      return comment['parentCommentId'] == null;

    }).toList();

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Comments',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Column(
        children: [

          // ======================================================
          // COMMENTS
          // ======================================================

          Expanded(

            child: _isLoading

                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )

                : _comments.isEmpty

                    ? const Center(
                        child: Text(
                          'No comments yet.\n'
                          'Be the first to comment!',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                      )

                    : ListView.separated(

                        padding:
                            const EdgeInsets.all(16),

                        itemCount:
                            topLevelComments.length,

                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                          height: 16,
                        ),

                        itemBuilder:
                            (context, index) {

                          final comment =
                              topLevelComments[index];

                          // ------------------------------------------------
                          // FIND REPLIES
                          // ------------------------------------------------

                          final List<Map<String, dynamic>> threadReplies = [];

                          void collectReplies(
                            Map<String, dynamic> parentComment,
                          ) {
                            final parentId =
                                parentComment['commentID']?.toString();

                            if (parentId == null) return;

                            final children = _comments.where((reply) {
                              return reply['parentCommentId']?.toString() ==
                                  parentId;
                            }).toList();

                            for (final child in children) {
                              threadReplies.add(child);
                              collectReplies(child);
                            }
                          }

                          collectReplies(comment);

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              // ==================================================
                              // MAIN COMMENT
                              // ==================================================

                              _buildComment(
                                comment,
                                isReply: false,
                              ),

                              // ==================================================
                              // REPLIES
                              // ==================================================

                              if (threadReplies.isNotEmpty)

                                Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    left: 42,
                                    top: 8,
                                  ),

                                  child: Column(
                                    children:
                                        threadReplies.map(
                                      (reply) {

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(
                                            bottom: 12,
                                          ),

                                          child:
                                              _buildComment(
                                            reply,
                                            isReply: true,
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          ),

          // ======================================================
          // INPUT
          // ======================================================

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8,
              ),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  // ==================================================
                  // REPLYING TO
                  // ==================================================

                  if (_replyingTo != null)

                    Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 6,
                        left: 8,
                        right: 8,
                      ),

                      child: Row(
                        children: [

                          Expanded(
                            child: Text(
                              'Replying to @${_getUsername(_replyingTo!)}',

                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    AppColors.textSecondary,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap:
                                _cancelReply,

                            child:
                                const Icon(
                              Icons.close,
                              size: 18,
                              color:
                                  AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==================================================
                  // TEXT FIELD
                  // ==================================================

                  Row(
                    children: [

                      Expanded(
                        child: TextField(
                          controller:
                              _commentController,

                          textInputAction:
                              TextInputAction.send,

                          onSubmitted: (_) {

                            if (!_isSending) {
                              _addComment();
                            }
                          },

                          decoration:
                              InputDecoration(

                            hintText:
                                _replyingTo != null
                                    ? 'Write a reply...'
                                    : 'Write a comment...',

                            filled: true,

                            fillColor:
                                AppColors.chipGrey,

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                24,
                              ),

                              borderSide:
                                  BorderSide.none,
                            ),

                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      IconButton(

                        onPressed:
                            _isSending
                                ? null
                                : _addComment,

                        icon:

                            _isSending

                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )

                                : const Icon(
                                    Icons.send,
                                    color:
                                        AppColors.primary,
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

  // ============================================================
  // COMMENT WIDGET
  // ============================================================

  Widget _buildComment(
    Map<String, dynamic> comment, {
    required bool isReply,
  }) {

    final profile =
        comment['profiles'];

    final username =
        profile?['username']
                ?.toString() ??
            'Unknown User';

    final profilePhoto =
        profile?['profilePhotoUrl']
                ?.toString();

    final isVerified = profile?['is_verified'] == true;

    final commentText =
        comment['comment']
                ?.toString() ??
            '';

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        // ========================================================
        // PROFILE PHOTO
        // ========================================================

        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OtherUserProfilePage(
                  userId: comment['userID'].toString(),
                ),
              ),
            );
          },
          child: CircleAvatar(

            radius:
                isReply ? 16 : 18,

            backgroundColor:
                AppColors.placeholder,

            backgroundImage:

                profilePhoto != null &&
                        profilePhoto.isNotEmpty

                    ? NetworkImage(
                        profilePhoto,
                      )

                    : null,

            child:

                profilePhoto == null ||
                        profilePhoto.isEmpty

                    ? Icon(
                        Icons.person,
                        size:
                            isReply ? 16 : 20,
                        color:
                            AppColors.textSecondary,
                      )

                    : null,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        // ========================================================
        // COMMENT CONTENT
        // ========================================================

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // USERNAME
             Row(
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfilePage(
                            userId: comment['userID'].toString(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isReply ? 13 : 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.verified,
                    size: isReply ? 12 : 13,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),

              const SizedBox(
                height: 3,
              ),

              // COMMENT

              Text(
                commentText,

                style: TextStyle(
                  fontSize:
                      isReply ? 13 : 14,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              // TIME + REPLY

              Row(
                children: [

                  Text(
                    _formatCommentTime(
                      comment['created_at'],
                    ),

                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  GestureDetector(

                    onTap: () {
                      _startReply(
                        comment,
                      );
                    },

                    child:
                        const Text(
                      'Reply',

                      style:
                          TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GET USERNAME
  // ============================================================

  String _getUsername(
    Map<String, dynamic> comment,
  ) {

    final profile =
        comment['profiles'];

    return profile?['username']
            ?.toString() ??
        'Unknown User';
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _formatCommentTime(
    dynamic value,
  ) {

    if (value == null) return '';

    final date =
        DateTime.parse(
      value.toString(),
    ).toLocal();

    final now =
        DateTime.now();

    final difference =
        now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}