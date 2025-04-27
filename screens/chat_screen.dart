import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'faq_screen.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; 
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'Opportunities.dart'; // adjust if your file has a different name
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';



class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _typingAnimationController;
  
  bool _showSuggestions = true;
  bool _isDarkMode = true;
  bool _isOnline = true;
  bool _isSettingsOpen = false;
  bool _isSearchOpen = false;
  bool _isFormattingToolbarOpen = false;
  late stt.SpeechToText _speech;
bool _isListening = false;
  bool _isBoldActive = false;
  bool _isItalicActive = false;
  bool _isUnderlineActive = false;
  String _selectedFocusArea = 'Women in Tech';
  String _selectedPersonality = 'Professional';
  final TextEditingController _searchController = TextEditingController();
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;
  bool _isOpportunitiesOpen = false;
double _canvasWidth = 300;
List<Map<String, dynamic>> _pendingFiles = [];



  // Supabase and session variables
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();
  String? _sessionId;
  DateTime? _sessionStartTime;
  bool _isSessionActive = false;

  List<Map<String, dynamic>> messages = [
    {
      'sender': 'asha',
      'text': "I'm Asha , your AI assistant...focused on women in tech topics. How can I help you today?",
      'timestamp': DateTime.now(),
      'reactions': [],
      //'isFormatted': false,
      'formats': {},
    },
  ];

  bool isTyping = false;




  @override
  void initState() {
    super.initState();
    _startNewSession();
    _loadMessagesFromStorage();
    _speech = stt.SpeechToText();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
@override
  void dispose() {
    _trackSessionEnd();
    _typingAnimationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
      );
    }
  }

  void _jumpToSearchResult(int resultIndex) {
    if (_searchResults.isEmpty || resultIndex < 0 || resultIndex >= _searchResults.length) {
      return;
    }
    
    final messageIndex = _searchResults[resultIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemHeight = 100.0;
      final position = messageIndex * itemHeight;
      
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }
   Widget _buildFocusChip(String label) {
    final isSelected = _selectedFocusArea == label;
    return FilterChip(
      selected: isSelected,
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: Colors.deepPurple,
      checkmarkColor: Colors.white,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFocusArea = label;
        });
      },
    );
  }
  Widget _buildPersonalityChip(String label) {
    final isSelected = _selectedPersonality == label;
    return FilterChip(
      selected: isSelected,
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: Colors.deepPurple,
      checkmarkColor: Colors.white,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _selectedPersonality = label;
        });
      },
    );
  }
  void _startNewSession() {
    setState(() {
      _sessionId = _uuid.v4();
      _sessionStartTime = DateTime.now();
      _isSessionActive = true;
    });
    _trackSessionStart();
  }

  Future<void> _trackSessionStart() async {
    try {
      await _supabase.from('sessions').insert({
        'session_id': _sessionId,
        'start_time': _sessionStartTime?.toIso8601String(),
        'focus_area': _selectedFocusArea,
        'personality': _selectedPersonality,
      });
    } catch (e) {
      debugPrint('Error tracking session start: $e');
    }
  }

  Future<void> _trackSessionEnd() async {
  if (!_isSessionActive || _sessionId == null) return;
  
  try {
    await _supabase.from('sessions').update({
      'end_time': DateTime.now().toIso8601String(),
    }).eq('session_id', _sessionId!);
    
    setState(() {
      _isSessionActive = false;
    });
  } catch (e) {
    debugPrint('Error tracking session end: $e');
  }
}

  

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
    });
  }

  void _showMessageOptions(Map<String, dynamic> message, int index, BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: const Text('Copy'),
          onTap: () {
            Clipboard.setData(ClipboardData(text: message['text']));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Message copied'),
                backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.green,
              ),
            );
          },
        ),
        PopupMenuItem(
          child: const Text('Delete'),
          onTap: () {
            setState(() {
              messages.removeAt(index);
            });
          },
        ),
        if (message['sender'].toString().toLowerCase() == 'asha') PopupMenuItem(
          child: const Text('Reply'),
          onTap: () {
            _controller.text = 'Re: ${message['text']}';
            _focusNode.requestFocus();
          },
        ),
      ],
    );
  }
  Future<void> _saveMessagesToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> storedMessages = messages.map((m) => jsonEncode(m)).toList();
  await prefs.setStringList('chat_messages', storedMessages);
}
Future<void> _uploadFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,  // Allow multiple file selection
      withData: true,       // Ensure we get file bytes
    );

    if (result == null || result.files.isEmpty) return;

    for (var file in result.files) {
      if (file.bytes == null) continue;

      // Show confirmation dialog for each file
      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Upload ${file.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (['jpg', 'png', 'jpeg'].contains(file.extension?.toLowerCase()))
                Image.memory(file.bytes!, height: 150),
              if (file.extension?.toLowerCase() == 'pdf')
                Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
              if (['doc', 'docx'].contains(file.extension?.toLowerCase()))
                Icon(Icons.description, size: 50, color: Colors.blue),
              const SizedBox(height: 8),
              Text('${file.size ~/ 1024} KB', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (file.extension != null)
                Text('Type: ${file.extension!.toUpperCase()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload', 
                  style: TextStyle(color: Colors.deepPurple)),
            ),
          ],
        ),
      );

      if (shouldUpload != true) continue;

      // Show upload progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white)),
              const SizedBox(width: 16),
              Text('Uploading ${file.name}...'),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          duration: const Duration(seconds: 5),
        ),
      );

      try {
        // Upload to Supabase storage
        final storageFilePath = 'attachments/${_uuid.v4()}_${file.name}';
        await _supabase.storage
            .from('chatfiles')
            .uploadBinary(storageFilePath, file.bytes!);

        final fileUrl = _supabase.storage
            .from('chatfiles')
            .getPublicUrl(storageFilePath);

        // Add to pending files
        setState(() {
          _pendingFiles.add({
            'name': file.name,
            'bytes': file.bytes,
            'extension': file.extension,
            'size': file.size,
            'url': fileUrl,
          });
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload ${file.name}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _uploadFile(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        continue; // Skip to next file if upload fails
      }
    }

    if (_pendingFiles.isNotEmpty) {
      _scrollToBottom();
      _focusNode.requestFocus();
    }
  } catch (e) {
    debugPrint('File upload error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _uploadFile(),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
Future<void> _loadMessagesFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final List<String>? storedMessages = prefs.getStringList('chat_messages');
  if (storedMessages != null) {
    setState(() {
      messages = storedMessages.map((m) => jsonDecode(m) as Map<String, dynamic>).toList();
    });
  }
}
void _listen() async {
  if (!_isListening) {
    bool available = await _speech.initialize(
      onStatus: (val) => debugPrint('onStatus: $val'),
      onError: (val) => debugPrint('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _controller.text = val.recognizedWords;
        }),
      );
    }
  } else {
    setState(() => _isListening = false);
    _speech.stop();
  }
}

 
  Future<void> _uploadPendingFiles(String messageId) async {
    for (var file in _pendingFiles) {
      try {
        final storageFilePath = 'attachments/${_uuid.v4()}_${file['name']}';
        
        // For web, we already have the URL, no need to upload again
        if (kIsWeb && file['url'] != null) {
          await _supabase.from('attachments').insert({
            'message_id': messageId,
            'session_id': _sessionId,
            'file_name': file['name'],
            'file_path': storageFilePath,
            'file_url': file['url'],
            'file_type': file['extension'],
            'file_size': file['size'],
            'uploaded_at': DateTime.now().toIso8601String(),
          });
          continue;
        }

        // For mobile/desktop, upload the file bytes
        if (file['bytes'] != null) {
          await _supabase.storage
              .from('chatfiles')
              .uploadBinary(storageFilePath, file['bytes']);

          final fileUrl = _supabase.storage
              .from('chatfiles')
              .getPublicUrl(storageFilePath);

          await _supabase.from('attachments').insert({
            'message_id': messageId,
            'session_id': _sessionId,
            'file_name': file['name'],
            'file_path': storageFilePath,
            'file_url': fileUrl,
            'file_type': file['extension'],
            'file_size': file['size'],
            'uploaded_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
      }
    }
    setState(() {
      _pendingFiles.clear();
    });
  }
Future<void> sendMessage(String text) async {
  if (text.trim().isEmpty && _pendingFiles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a message or attach a file')),
    );
    return;
  }

  // Get text formatting data
  Map<String, dynamic> formats = {
    'bold': _isBoldActive,
    'italic': _isItalicActive,
    'underline': _isUnderlineActive,
  };

  // Prepare files for API
  List<Map<String, dynamic>> filesData = _pendingFiles.map((file) {
    return {
      'file_name': file['name'],
      'file_data': file['bytes'] != null ? base64Encode(file['bytes']!) : null,
      'file_type': file['extension'],
      'file_size': file['size'],
    };
  }).toList();

  // Get opportunities data if needed
  Map<String, dynamic>? opportunitiesData;
  if (_isOpportunitiesOpen || 
      text.toLowerCase().contains('job') || 
      text.toLowerCase().contains('career') ||
      text.toLowerCase().contains('opportunity')) {
    opportunitiesData = await _getOpportunitiesData();
  }

  // Create the payload for API
  final payload = {
    'session_id': _sessionId,
    'has_files': _pendingFiles.isNotEmpty,
    if (text.trim().isNotEmpty) 'message': text.trim(),
    if (_pendingFiles.isNotEmpty) 'files': filesData,
    if (opportunitiesData != null) 'opportunities_data': opportunitiesData,
  };

  debugPrint('Sending payload: ${json.encode(payload)}');

  // Create user message for local storage
  final userMessage = {
    'sender': 'user',
    'text': text.trim().isEmpty ? '[Files attached]' : text.trim(),
    'timestamp': DateTime.now().toIso8601String(),
    'reactions': [],
    'formats': formats,
    'session_id': _sessionId,
    'has_files': _pendingFiles.isNotEmpty,
    'files': _pendingFiles.map((f) => f['name']).toList(),
  };

  try {
    // Store message in Supabase
    final response = await _supabase.from('messages').insert(userMessage).select();
    final messageId = response.first['id'].toString();

    // Upload any pending files to storage
    if (_pendingFiles.isNotEmpty) {
      await _uploadPendingFiles(messageId);
    }

    // Update local state
    setState(() {
      messages.add({
        ...userMessage,
        'timestamp': DateTime.now(),
        'animationKey': UniqueKey(),
      });
      isTyping = true;
      _controller.clear();
      _showSuggestions = false;
      _isFormattingToolbarOpen = false;
      _isBoldActive = false;
      _isItalicActive = false;
      _isUnderlineActive = false;
    });
    _saveMessagesToStorage();
    _scrollToBottom();

    // Send to backend API
    final apiResponse = await http.post(
      Uri.parse('https://yeshasvi19-chat.hf.space/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 30));

    debugPrint('API Response Status: ${apiResponse.statusCode}');
    debugPrint('API Response Body: ${apiResponse.body}');

    if (apiResponse.statusCode == 200) {
      final responseData = json.decode(apiResponse.body);
      final aiResponse = {
        'sender': 'asha',
        'text': responseData['response'],
        'timestamp': DateTime.now().toIso8601String(),
        'reactions': [],
        'formats': {},
        'session_id': _sessionId,
        'has_files': false,
      };

      await _supabase.from('messages').insert(aiResponse);

      setState(() {
        messages.add({
          ...aiResponse,
          'timestamp': DateTime.now(),
          'animationKey': UniqueKey(),
        });
        isTyping = false;
        _pendingFiles.clear(); // Clear files after successful send
      });
      _saveMessagesToStorage();
      _scrollToBottom();
    } else {
      throw Exception('API request failed with status ${apiResponse.statusCode}: ${apiResponse.body}');
    }
  } catch (e) {
    debugPrint('Error in sendMessage: $e');
    setState(() {
      isTyping = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error sending message: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => sendMessage(text),
        ),
      ),
    );
  }
}  Future<Map<String, dynamic>?> _getOpportunitiesData() async {
    if (!_isOpportunitiesOpen) return null;
    
    // This would come from your OpportunitiesScreen state
    // For now, returning mock data - implement based on your app
    return {
      'skills': ['Programming', 'Leadership'],
      'interests': ['AI', 'Web Development'],
      'experience_level': 'Intermediate',
      'preferred_roles': ['Developer', 'Manager'],
    };
  }
 Widget _buildFilePreview() {
  if (_pendingFiles.isEmpty) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Files to send:',
          style: TextStyle(
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _pendingFiles.map((file) {
            return Chip(
              backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
              label: Text(
                file['name'],
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              avatar: Icon(
                _getFileIcon(file['extension']),
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              deleteIcon: Icon(
                Icons.close,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              onDeleted: () {
                setState(() {
                  _pendingFiles.remove(file);
                });
              },
            );
          }).toList(),
        ),
      ],
    ),
  );
}
  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }
Future<void> _downloadChat() async {
  if (_sessionId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No active session to export'),
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.red,
      ),
    );
    return;
  }

  try {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('session_id', _sessionId!)
        .order('timestamp');
    
    final messages = response as List<dynamic>;
    
    final String chatData = messages.map((msg) {
      final sender = msg['sender'] == 'asha' ? 'Asha AI' : 'You';
      final time = DateTime.parse(msg['timestamp']).toLocal().toString();
      return '[$time] $sender: ${msg['text']}';
    }).join('\n\n');
    
    final title = 'Asha Chat - ${DateTime.now().toString().split('.')[0]}';
    final content = '$title\n\nSession ID: $_sessionId\n\n$chatData';
    
    if (kIsWeb) {
      // Web-specific download
      final blob = html.Blob([content], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = 'Asha_chat_export.txt'
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/desktop download
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/asha_chat_export.txt');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'asha Chat History');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat history exported successfully'),
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error exporting chat: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchController.clear();
        _searchResults.clear();
        _currentSearchIndex = -1;
      }
    });
  }
  
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = -1;
      });
      return;
    }
    
    final results = <int>[];
    for (int i = 0; i < messages.length; i++) {
      if (messages[i]['text'].toString().toLowerCase().contains(query.toLowerCase())) {
        results.add(i);
      }
    }
    
    setState(() {
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
      
      if (_currentSearchIndex >= 0) {
        _jumpToSearchResult(_currentSearchIndex);
      }
    });
  }
  

  
  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;
    
    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
      _jumpToSearchResult(_currentSearchIndex);
    });
  }
  
  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;
    
    setState(() {
      _currentSearchIndex = (_currentSearchIndex - 1 + _searchResults.length) % _searchResults.length;
      _jumpToSearchResult(_currentSearchIndex);
    });
  }

  void _toggleFormattingToolbar() {
    setState(() {
      _isFormattingToolbarOpen = !_isFormattingToolbarOpen;
    });
    _focusNode.requestFocus();
  }

  void _toggleBold() {
    setState(() {
      _isBoldActive = !_isBoldActive;
    });
    _focusNode.requestFocus();
  }
  
  void _toggleItalic() {
    setState(() {
      _isItalicActive = !_isItalicActive;
    });
    _focusNode.requestFocus();
  }

  void _toggleUnderline() {
    setState(() {
      _isUnderlineActive = !_isUnderlineActive;
    });
    _focusNode.requestFocus();
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _typingAnimationController,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final position = math.sin((_typingAnimationController.value * 2 * math.pi) + delay) * 0.5 + 0.5;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.5 + position * 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Asha is typing...',
            style: TextStyle(
              color: _isDarkMode ? Colors.grey[300] : Colors.deepPurple[300],
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.format_bold,
              color: _isBoldActive 
                  ? Colors.deepPurple 
                  : (_isDarkMode ? Colors.white : Colors.black),
            ),
            onPressed: _toggleBold,
          ),
          IconButton(
            icon: Icon(
              Icons.format_italic,
              color: _isItalicActive 
                  ? Colors.deepPurple 
                  : (_isDarkMode ? Colors.white : Colors.black),
            ),
            onPressed: _toggleItalic,
          ),
          IconButton(
            icon: Icon(
              Icons.format_underline,
              color: _isUnderlineActive 
                  ? Colors.deepPurple 
                  : (_isDarkMode ? Colors.white : Colors.black),
            ),
            onPressed: _toggleUnderline,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      color: _isDarkMode ? const Color(0xFF212121) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: _isDarkMode ? Colors.white : Colors.grey[700],
            ),
            onPressed: _toggleSearch,
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search chat...',
                hintStyle: TextStyle(
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                ),
                border: InputBorder.none,
              ),
              onChanged: _performSearch,
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            Text(
              '${_currentSearchIndex + 1}/${_searchResults.length}',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.grey[700],
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: _isDarkMode ? Colors.white : Colors.grey[700],
              ),
              onPressed: _previousSearchResult,
            ),
            IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: _isDarkMode ? Colors.white : Colors.grey[700],
              ),
              onPressed: _nextSearchResult,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMessageReactions(List<dynamic> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 4,
      children: reactions.map<Widget>((reaction) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Color(reaction['color']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            IconData(reaction['icon'], fontFamily: 'MaterialIcons'),
            size: 14,
            color: Color(reaction['color']),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsPanel() {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Asha AI Settings',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSettings,
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _isDarkMode,
                    activeColor: Colors.deepPurple[200],
                    activeTrackColor: Colors.deepPurple,
                    inactiveThumbColor: Colors.grey[300],
                    inactiveTrackColor: Colors.grey[600],
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Focus Area', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFocusChip('Women in Tech'),
                    const SizedBox(width: 8),
                    _buildFocusChip('Career'),
                    const SizedBox(width: 8),
                    _buildFocusChip('Tech General'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Personality Style', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPersonalityChip('Professional'),
                    const SizedBox(width: 8),
                    _buildPersonalityChip('Friendly'),
                    const SizedBox(width: 8),
                    _buildPersonalityChip('Concise'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 List<TextSpan> _buildHighlightedSpans(String text, List<Match> matches) {
  if (matches.isEmpty) return [TextSpan(text: text)];
  
  final spans = <TextSpan>[];
  int currentPos = 0;
  
  for (final match in matches) {
    if (match.start > currentPos) {
      spans.add(TextSpan(text: text.substring(currentPos, match.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    currentPos = match.end;
  }
  
  if (currentPos < text.length) {
    spans.add(TextSpan(text: text.substring(currentPos)));
  }
  
  return spans;
}
Widget buildMessage(Map<String, dynamic> msg, int index) {
  bool isAsha = msg['sender'].toString().toLowerCase() == 'asha';
  final messageTime = TimeOfDay.fromDateTime(msg['timestamp']).format(context);
  final isHighlighted = _searchResults.isNotEmpty &&
      _currentSearchIndex >= 0 &&
      _searchResults[_currentSearchIndex] == index;

  final ashaAvatar = CircleAvatar(
    backgroundColor: Colors.deepPurple[200],
    radius: 16,
    child: const Icon(
      Icons.engineering,
      color: Colors.white,
      size: 18,
    ),
  );

  final userAvatar = CircleAvatar(
    backgroundColor: Colors.deepPurple[600],
    radius: 16,
    child: const Text(
      'U',
      style: TextStyle(color: Colors.white),
    ),
  );

  Widget textWidget = MarkdownBody(
    data: msg['text'] ?? '',
    styleSheet: MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 15,
        color: isAsha
            ? (_isDarkMode ? Colors.white : Colors.black)
            : Colors.white,
      ),
      a: const TextStyle(
        color: Colors.blueAccent,
        decoration: TextDecoration.underline,
      ),
      code: TextStyle(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
        fontFamily: 'monospace',
      ),
    ),
    onTapLink: (text, href, title) {
      if (href != null) {
        launchUrl(Uri.parse(href));
      }
    },
  );

  if (msg['has_files'] == true) {
    final files = msg['files'] as List<dynamic>?;

    if (files != null && files.isNotEmpty) {
      textWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg['text']?.isNotEmpty == true) textWidget,
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: files.map((fileName) {
              return Chip(
                backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                label: Text(
                  fileName.toString(),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                avatar: Icon(
                  _getFileIcon(fileName.toString().split('.').last),
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            'Attachments: ${files.length} file(s)',
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      );
    }
  }

  return TweenAnimationBuilder<double>(
    key: msg['animationKey'],
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutQuad,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      );
    },
    child: GestureDetector(
      onLongPressStart: (details) {
        _showMessageOptions(msg, index, context, details.globalPosition);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: isHighlighted
            ? BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        padding: isHighlighted ? const EdgeInsets.all(4) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isAsha ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isAsha) ashaAvatar,
            if (isAsha) const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isAsha ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAsha
                          ? (_isDarkMode ? Colors.grey[800] : Colors.white)
                          : Colors.deepPurple[600],
                      borderRadius: BorderRadius.circular(18),
                      border: isAsha && _isDarkMode
                          ? Border.all(color: Colors.grey[700]!)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isAsha ? 0.05 : 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: textWidget,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        messageTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildMessageReactions(msg['reactions'] ?? []),
                    ],
                  ),
                ],
              ),
            ),
            if (!isAsha) const SizedBox(width: 8),
            if (!isAsha) userAvatar,
          ],
        ),
      ),
    ),
  );
}  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? const Color(0xFF121212) : Colors.white;
    final headerColor = _isDarkMode ? const Color(0xFF212121) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final drawerTextColor = _isDarkMode ? Colors.white : Colors.black;
    final drawerHeaderColor = _isDarkMode ? const Color(0xFF2D2D2D) : Colors.deepPurple;

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Drawer(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: drawerHeaderColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple[200],
                    radius: 24,
                    child: const Icon(
                      Icons.engineering,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Asha AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Empowering Women in Tech',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.chat,
                color: drawerTextColor,
              ),
              title: Text(
                'Chat',
                style: TextStyle(color: drawerTextColor),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.help_outline,
                color: drawerTextColor,
              ),
              title: Text(
                'FAQ',
                style: TextStyle(color: drawerTextColor),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQScreen(isDarkMode: _isDarkMode)),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: drawerTextColor,
              ),
              title: Text(
                'Settings',
                style: TextStyle(color: drawerTextColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleSettings();
              },
            ),
          ],
        ),
      ),
      appBar: _isSearchOpen
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildSearchPanel(),
            )
          : AppBar(
              backgroundColor: headerColor,
              elevation: 1,
              shadowColor: Colors.black12,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asha',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  onPressed: _downloadChat,
                ),
                IconButton(
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                ),
              ],
            ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: Text(
                        'Today',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.blue : Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: backgroundColor,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: messages.length + (isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < messages.length) {
                              return buildMessage(messages[index], index);
                            } else {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: _buildTypingIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    if (_isFormattingToolbarOpen) _buildFormattingToolbar(),
                    _buildFilePreview(),
                    Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        border: Border(
                          top: BorderSide(
                            color: _isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.attach_file),
                                        onPressed: _uploadFile,
                                        tooltip: 'Attach file',
                                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                      ),
                                      Expanded(
                                        child: TextField(
                                          focusNode: _focusNode,
                                          controller: _controller,
                                          keyboardType: TextInputType.multiline,
                                          textCapitalization: TextCapitalization.sentences,
                                          textInputAction: TextInputAction.send,
                                          style: TextStyle(
                                            color: _isDarkMode ? Colors.white : Colors.black,
                                            fontWeight: _isBoldActive ? FontWeight.bold : FontWeight.normal,
                                            fontStyle: _isItalicActive ? FontStyle.italic : FontStyle.normal,
                                            decoration: _isUnderlineActive ? TextDecoration.underline : TextDecoration.none,
                                          ),
                                          maxLines: 5,
                                          minLines: 1,
                                          decoration: InputDecoration(
                                            hintText: 'Type your message here...',
                                            hintStyle: TextStyle(
                                              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                              fontWeight: _isBoldActive ? FontWeight.bold : FontWeight.normal,
                                              fontStyle: _isItalicActive ? FontStyle.italic : FontStyle.normal,
                                              decoration: _isUnderlineActive ? TextDecoration.underline : TextDecoration.none,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          onSubmitted: sendMessage,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.format_bold,
                                                color: _isBoldActive 
                                                    ? Colors.deepPurple 
                                                    : (_isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                                size: 20,
                                              ),
                                              onPressed: _toggleBold,
                                            ),
                                            IconButton(
                                              icon: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: _isListening
                                                    ? const Icon(Icons.mic_off, key: ValueKey('mic_off'))
                                                    : const Icon(Icons.mic, key: ValueKey('mic')),
                                              ),
                                              color: _isListening 
                                                  ? Colors.red 
                                                  : (_isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                              onPressed: () {
                                                if (_isListening) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Voice input complete'),
                                                      backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.green,
                                                    ),
                                                  );
                                                }
                                                _listen();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: const BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  onTap: () => sendMessage(_controller.text),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Press Enter to send',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.grey[600] : Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.work_outline),
                                  onPressed: () {
                                    setState(() {
                                      _isOpportunitiesOpen = !_isOpportunitiesOpen;
                                    });
                                  },
                                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                  iconSize: 20,
                                  tooltip: 'Opportunities',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isSettingsOpen)
                  GestureDetector(
                    onTap: _toggleSettings,
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: _buildSettingsPanel(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: _isOpportunitiesOpen ? _canvasWidth : 0,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF121212) : Colors.white,
              border: Border(
                left: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
              ),
            ),
            child: _isOpportunitiesOpen ? _buildOpportunitiesPanel() : null,
          ),
        ],
      ),
      bottomNavigationBar: _isDarkMode ? null : Container(
        height: 24,
        color: Colors.grey[100],
        child: Center(
          child: Text(
            '© 2025 Asha Chat — Empowering Women in Technology',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildOpportunitiesPanel() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _canvasWidth -= details.delta.dx;
          if (_canvasWidth < 200) _canvasWidth = 200;
          if (_canvasWidth > 500) _canvasWidth = 500;
          
          // Swipe left to close
          if (details.delta.dx < -20) {
            _isOpportunitiesOpen = false;
          }
        });
      },
      child: OpportunitiesScreen(),
    );
  }
}