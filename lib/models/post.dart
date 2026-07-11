/// A single community post shown on the Home screen / Profile "Post" tab.
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? caption;
  final String? imageUrl;
  final List<String> keywords; // e.g. Discussion, Cats, Adoption, Rescue, Dogs
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.caption,
    this.imageUrl,
    this.keywords = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
  });

  // ---------------------------------------------------------------------
  // DB (Supabase) — maps to a future `posts` table joined with `profiles`.
  // ---------------------------------------------------------------------
  // factory Post.fromMap(Map<String, dynamic> map) {
  //   return Post(
  //     id: map['id'] as String,
  //     authorId: map['author_id'] as String,
  //     authorName: map['author_name'] as String? ?? 'Unknown',
  //     authorAvatarUrl: map['author_avatar_url'] as String?,
  //     caption: map['caption'] as String?,
  //     imageUrl: map['image_url'] as String?,
  //     keywords: List<String>.from(map['keywords'] ?? const []),
  //     likeCount: map['like_count'] as int? ?? 0,
  //     commentCount: map['comment_count'] as int? ?? 0,
  //     createdAt: DateTime.parse(map['created_at'] as String),
  //   );
  // }
}

/// A comment left on a [Post], shown on the Profile "Comments" tab.
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String repliedToCaptionPreview;
  final String body;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.repliedToCaptionPreview,
    required this.body,
    required this.createdAt,
  });
}