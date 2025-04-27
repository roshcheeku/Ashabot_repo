import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final TextEditingController keywordController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController eventQueryController = TextEditingController();

  String jobResults = '';
  String eventResults = '';
  String mentorshipResults = '';

  bool isLoadingJobs = false;
  bool isLoadingEvents = false;
  bool isLoadingMentorship = false;

  bool showJobInput = false;
  bool showEventInput = false;
  bool _darkMode = false;

  ThemeData get _theme => _darkMode 
      ? ThemeData.dark().copyWith(
          primaryColor: Colors.indigo,
          scaffoldBackgroundColor: Colors.grey[900],
          cardColor: Colors.grey[800],
        )
      : ThemeData.light().copyWith(
          primaryColor: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        );

  Future<void> fetchJobs() async {
    final keyword = keywordController.text;
    final location = locationController.text;

    if (keyword.isEmpty || location.isEmpty) {
      setState(() {
        jobResults = 'Please enter both keyword and location.';
      });
      return;
    }

    setState(() {
      isLoadingJobs = true;
      jobResults = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://dhanya-26-jobs.hf.space/jobs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'keywords': keyword, 'location': location}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          jobResults = data['formattedJobs'] ?? 'No jobs found.';
        });
      } else {
        setState(() {
          jobResults = 'Error fetching jobs.';
        });
      }
    } catch (e) {
      setState(() {
        jobResults = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoadingJobs = false;
      });
    }
  }

  Future<void> fetchEvents() async {
    final query = eventQueryController.text;

    if (query.isEmpty) {
      setState(() {
        eventResults = 'Please enter a search query for events.';
      });
      return;
    }

    setState(() {
      isLoadingEvents = true;
      eventResults = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://Dhanya-26-events.hf.space/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          eventResults = data['events'] ?? 'No events found.';
        });
      } else {
        setState(() {
          eventResults = 'Error fetching events.';
        });
      }
    } catch (e) {
      setState(() {
        eventResults = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoadingEvents = false;
      });
    }
  }

  Future<void> fetchMentorship() async {
    const query = "mentorship programs for women in technology 2025";

    setState(() {
      isLoadingMentorship = true;
      mentorshipResults = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://Dhanya-26-mentorship.hf.space/mentorship?query=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          mentorshipResults = data['mentorship'] ?? 'No mentorships found.';
        });
      } else {
        setState(() {
          mentorshipResults = 'Error fetching mentorships.';
        });
      }
    } catch (e) {
      setState(() {
        mentorshipResults = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoadingMentorship = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return MaterialApp(
      theme: _theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Opportunities'),
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _darkMode = !_darkMode;
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: _darkMode
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFF5F7FA), Color(0xFFE4ECF2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              color: _darkMode ? Colors.grey[900] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 340,
                    height: screenHeight * 0.2,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
                      image: const DecorationImage(
                        image: AssetImage('assets/image.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          FeatureIcon(
                            icon: Icons.work_outline,
                            title: 'JOBS',
                            onTap: () {
                              setState(() {
                                showJobInput = !showJobInput;
                                showEventInput = false;
                                eventResults = '';
                                mentorshipResults = '';
                              });
                            },
                            darkMode: _darkMode,
                          ),
                          FeatureIcon(
                            icon: Icons.event_note_outlined,
                            title: 'EVENTS',
                            onTap: () {
                              setState(() {
                                showEventInput = !showEventInput;
                                showJobInput = false;
                                jobResults = '';
                                mentorshipResults = '';
                              });
                            },
                            darkMode: _darkMode,
                          ),
                          FeatureIcon(
                            icon: Icons.support_agent,
                            title: 'MENTORSHIP',
                            onTap: fetchMentorship,
                            darkMode: _darkMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showJobInput) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Keyword", style: TextStyle(color: _darkMode ? Colors.white : Colors.black)),
                        TextField(
                          controller: keywordController,
                          style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _darkMode ? Colors.grey[800] : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text("Location", style: TextStyle(color: _darkMode ? Colors.white : Colors.black)),
                        TextField(
                          controller: locationController,
                          style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _darkMode ? Colors.grey[800] : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: fetchJobs,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                            child: const Text("Search Jobs"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isLoadingJobs)
                    const Center(child: CircularProgressIndicator())
                  else if (jobResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SelectableText(
                        jobResults, 
                        style: TextStyle(
                          fontSize: 14,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                ],
                if (showEventInput) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Event Search Query", style: TextStyle(color: _darkMode ? Colors.white : Colors.black)),
                        TextField(
                          controller: eventQueryController,
                          style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _darkMode ? Colors.grey[800] : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: fetchEvents,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                            child: const Text("Search Events"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isLoadingEvents)
                    const Center(child: CircularProgressIndicator())
                  else if (eventResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SelectableText(
                        eventResults, 
                        style: TextStyle(
                          fontSize: 14,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                ],
                if (isLoadingMentorship)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (mentorshipResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: SelectableText(
                      mentorshipResults, 
                      style: TextStyle(
                        fontSize: 14,
                        color: _darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool darkMode;

  const FeatureIcon({
    super.key, 
    required this.icon, 
    required this.title, 
    this.onTap,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: darkMode ? Colors.indigo.shade800 : Colors.indigo.shade100,
            child: Icon(icon, color: darkMode ? Colors.white : Colors.indigo, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 13, 
              color: darkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}