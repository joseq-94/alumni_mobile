class FeedPost {
  final int id;
  final String title;
  final String body;
  final String authorName;
  final DateTime createdAt;
  FeedPost({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'author_name': authorName,
    'created_at': createdAt.toIso8601String(),
  };
  factory FeedPost.fromMap(Map<String, dynamic> map) {
    return FeedPost(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      authorName: map['author_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
