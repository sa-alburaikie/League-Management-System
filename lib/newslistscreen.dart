import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewsListScreen extends StatefulWidget {
  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  String _selectedFilter = 'الكل';
  List<String> filterOptions = [
    'الكل',
    'اللاعبين',
    'المدربين',
    'الفرق',
  ];

  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<DocumentSnapshot> _newsDocs = [];

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchNews();
      }
    });
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoadingMore = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('news')
        .orderBy('date', descending: true)
        .limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _lastDocument = snapshot.docs.last;
        _newsDocs.addAll(snapshot.docs);
      });
    } else {
      setState(() {
        _hasMore = false;
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredNews = _selectedFilter == 'الكل'
        ? _newsDocs
        : _newsDocs
        .where((doc) => doc['target'] == _selectedFilter)
        .toList();

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF3D6F5D),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('قائمة الأخبار',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              items: filterOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'فلترة الأخبار حسب الفئة',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: filteredNews.length + 1,
              itemBuilder: (context, index) {
                if (index < filteredNews.length) {
                  final news = filteredNews[index];
                  return _buildNewsCard(news, context);
                } else {
                  return _isLoadingMore
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(DocumentSnapshot news, BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          news['title'] ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D6F5D),
          ),
        ),
        SizedBox(height: 8),
        Text(
          news['content'] ?? '',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الفئة: ${news['target']}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              _formatDate(news['date']),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF3D6F5D)),
              onPressed: () => _showEditDialog(context, news),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, news.id),
            ),
          ],
        )
      ],
    ),
        ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا الخبر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('news').doc(docId).delete();
              setState(() {
                _newsDocs.removeWhere((doc) => doc.id == docId);
              });
              Navigator.pop(context);
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot news) {
    final _titleController = TextEditingController(text: news['title']);
    final _contentController = TextEditingController(text: news['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل الخبر'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'عنوان الخبر'),
              ),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'محتوى الخبر'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('news')
                  .doc(news.id)
                  .update({
                'title': _titleController.text.trim(),
                'content': _contentController.text.trim(),
              });
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('حفظ', style: TextStyle(color: Color(0xFF3D6F5D))),
          ),
        ],
      ),
    );
  }
}