import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_theme.dart';

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

  // ------------------------------------------------------------
  // FETCH COMMENTS
  // ------------------------------------------------------------

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

            profiles (
              username,
              profilePhotoUrl
            )
          ''')
          .eq('strayID', widget.strayId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        _comments = List<Map<String, dynamic>>.from(data);
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

  // ------------------------------------------------------------
  // ADD COMMENT
  // ------------------------------------------------------------

  Future<void> _addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to comment.'),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await supabase
          .from('StrayReportComments')
          .insert({
            'strayID': widget.strayId,
            'userID': user.id,
            'comment': text,
          });

      _commentController.clear();

      await _fetchComments();
    } catch (e) {
      print('Error adding stray comment: $e');

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

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet.\nBe the first to comment!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];

                          final profile =
                              comment['profiles'];

                          final username =
                              profile?['username']
                                      ?.toString() ??
                                  'Unknown User';

                          final profilePhoto =
                              profile?['profilePhotoUrl']
                                      ?.toString();

                          final commentText =
                              comment['comment']
                                      ?.toString() ??
                                  '';

                          return Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppColors.placeholder,
                                backgroundImage:
                                    profilePhoto != null &&
                                            profilePhoto
                                                .isNotEmpty
                                        ? NetworkImage(
                                            profilePhoto,
                                          )
                                        : null,
                                child:
                                    profilePhoto == null ||
                                            profilePhoto
                                                .isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 20,
                                            color: AppColors
                                                .textSecondary,
                                          )
                                        : null,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 3,
                                    ),

                                    Text(
                                      commentText,
                                      style:
                                          const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      _formatCommentTime(
                                        comment['created_at'],
                                      ),
                                      style:
                                          const TextStyle(
                                        fontSize: 10,
                                        color: AppColors
                                            .textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // ------------------------------------------------------
          // COMMENT INPUT
          // ------------------------------------------------------

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) {
                        if (!_isSending) {
                          _addComment();
                        }
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Write a comment...',
                        filled: true,
                        fillColor:
                            AppColors.chipGrey,
                        border: OutlineInputBorder(
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

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed:
                        _isSending
                            ? null
                            : _addComment,
                    icon: _isSending
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.parse(
      value.toString(),
    ).toLocal();

    final now = DateTime.now();

    final difference = now.difference(date);

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