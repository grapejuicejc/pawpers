/// A single community post shown on the Home screen / Profile "Post" tab.
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? caption;
  final List<String> imageUrl;
  final List<String> keywords; // e.g. Discussion, Cats, Adoption, Rescue, Dogs
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool isLiked;
  final List<String> categories;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.caption,
    this.imageUrl = const [],
    this.keywords = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.isLiked = false,
    required this.categories,
  });

  //DATABASE
}

/// A comment left on a [Post], shown on the Profile "Comments" tab.
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;
   final String repliedToCaptionPreview;
  final String? postImageUrl;
  final String? postCaption;

  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
    required this.repliedToCaptionPreview,
    this.postImageUrl,
    this.postCaption,
  });
}
