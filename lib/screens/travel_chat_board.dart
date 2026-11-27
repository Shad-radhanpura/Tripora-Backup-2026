
import 'package:flutter/material.dart';

import '../theme/theme.dart';

class TravelChatBoard extends StatefulWidget {
  const TravelChatBoard({super.key});

  @override
  State<TravelChatBoard> createState() => _TravelChatBoardState();
}

class _TravelChatBoardState extends State<TravelChatBoard> {
  final TextEditingController _postController = TextEditingController();

  final List<Map<String, dynamic>> posts = [
    {
      'name': 'Priya Shah',
      'place': 'Goa',
      'text': 'Which are the best beaches to visit in Goa on a budget?',
      'likes': 12,
      'liked': false,
      'comments': ['Try Palolem Beach! It is beautiful.'],
      'color': Colors.pink,
    },
    {
      'name': 'Rahul Patel',
      'place': 'Manali',
      'text': 'Planning a 3-day Manali trip. Any suggestions for adventure lovers?',
      'likes': 8,
      'liked': false,
      'comments': ['Solang Valley is worth visiting!'],
      'color': Colors.blue,
    },
    {
      'name': 'Ananya Mehta',
      'place': 'Jaipur',
      'text': 'Jaipur has amazing forts and colourful markets. What is your favourite place?',
      'likes': 15,
      'liked': false,
      'comments': ['Visit Amer Fort early in the morning.'],
      'color': Colors.deepOrange,
    },
  ];

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _createPost() {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      posts.insert(0, {
        'name': 'You',
        'place': 'Travel Community',
        'text': text,
        'likes': 0,
        'liked': false,
        'comments': <String>[],
        'color': Colors.teal,
      });
      _postController.clear();
    });

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo post added successfully!')),
    );
  }

  void _showComments(Map<String, dynamic> post) {
    final controller = TextEditingController();
    final comments = post['comments'] as List<String>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 8, 20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comments',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (comments.isEmpty)
                const Text('Be the first to comment!')
              else
                ...comments.map(
                      (comment) => ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(comment),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: () {
                      if (controller.text.trim().isEmpty) return;
                      final comment = controller.text.trim();
                      setState(() => comments.add(comment));
                      refreshSheet(() {});
                      controller.clear();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      appBar: AppBar(
        title: const Text(
          'Travel Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5B45D6),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B45D6), Color(0xFF9A65E8)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your next adventure starts here! ✈️',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ask questions, share ideas and discover new places.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Explore discussions',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('${posts.length} posts',
                    style: const TextStyle(color: Colors.deepPurple)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final color = post['color'] as Color;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 14),
                  color: context.palette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(Icons.person, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '📍 ${post['place']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.public, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          post['text'],
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  final liked = post['liked'] as bool;
                                  post['liked'] = !liked;
                                  post['likes'] =
                                      (post['likes'] as int) + (liked ? -1 : 1);
                                });
                              },
                              icon: Icon(
                                post['liked']
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post['liked'] ? Colors.red : Colors.grey,
                              ),
                              label: Text('${post['likes']}'),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showComments(post),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(
                                '${(post['comments'] as List).length} Comments',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: context.palette.surface,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Share your travel question...',
                        filled: true,
                        fillColor: const Color(0xFFF3F0FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _createPost,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF5B45D6),
                      foregroundColor: Colors.white,
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
}
