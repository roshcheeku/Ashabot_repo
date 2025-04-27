import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  final bool isDarkMode;
  const FAQScreen({super.key, this.isDarkMode = true});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    // Define color scheme based on theme
    final backgroundColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = widget.isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = widget.isDarkMode ? Colors.white70 : Colors.black54;

    // FAQ data
    final List<Map<String, String>> faqItems = [
      {
        "question": "What is this chatbot?",
        "answer": "This chatbot will assist with answering your questions and providing relevant information once deployed. It's designed to help users find information quickly and efficiently."
      },
      {
        "question": "How can I interact with the chatbot?",
        "answer": "You will be able to type in your queries and receive responses from the chatbot in real time. The interface is designed to be intuitive and user-friendly."
      },
      {
        "question": "Is the chatbot intelligent?",
        "answer": "Yes, the chatbot uses machine learning and natural language processing to understand and respond to queries. It continuously improves through learning from interactions."
      },
      {
        "question": "How do I provide feedback on the chatbot?",
        "answer": "You can provide feedback in the feedback section once the chatbot is live. Your feedback helps us improve the chatbot's performance and accuracy."
      },
      {
        "question": "Will the chatbot be available on other platforms?",
        "answer": "Yes, the chatbot will be available on platforms like Telegram and WhatsApp as well. We're working on expanding to additional platforms to increase accessibility."
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: primaryColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Common questions about our chatbot',
                style: TextStyle(
                  fontSize: 16,
                  color: subtitleColor,
                ),
              ),
            ),
            
            // FAQ items
            ...List.generate(
              faqItems.length,
              (index) => _buildFAQCard(
                question: faqItems[index]["question"] ?? "",
                answer: faqItems[index]["answer"] ?? "",
                isExpanded: expandedIndex == index,
                onTap: () {
                  setState(() {
                    expandedIndex = expandedIndex == index ? null : index;
                  });
                },
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                primaryColor: primaryColor,
                margin: EdgeInsets.only(bottom: 16),
              ),
            ),
            
            // Additional help section
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.contact_support_outlined,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need more help?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact our support team for assistance with any other questions.',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard({
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color primaryColor,
    required EdgeInsets margin,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: primaryColor,
                      size: 20,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    answer,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}