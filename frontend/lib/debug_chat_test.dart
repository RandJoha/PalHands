import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/chat_service.dart';

class DebugChatTest extends StatefulWidget {
  const DebugChatTest({super.key});

  @override
  State<DebugChatTest> createState() => _DebugChatTestState();
}

class _DebugChatTestState extends State<DebugChatTest> {
  String _status = 'Ready to test...';
  bool _isLoading = false;

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing backend connection...';
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/chat/test'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = '✅ Backend connected: ${data['message']}';
        });
      } else {
        setState(() {
          _status = '❌ Backend error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Backend connection failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing authentication...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        setState(() {
          _status = '❌ Not authenticated. Please login first.';
        });
        return;
      }

      setState(() {
        _status = '✅ Authenticated as: ${authService.currentUser?['email'] ?? 'Unknown'}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Authentication test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testChatAPI() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing chat API...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final chatService = ChatService();
      
      if (!authService.isAuthenticated) {
        setState(() {
          _status = '❌ Not authenticated. Please login first.';
        });
        return;
      }

      final response = await chatService.getUserChats(authService: authService);
      
      if (response['success'] == true) {
        final chats = response['data']['chats'] as List<dynamic>;
        setState(() {
          _status = '✅ Chat API working! Found ${chats.length} chats.';
        });
      } else {
        setState(() {
          _status = '❌ Chat API error: ${response['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Chat API test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateChatWithProvider() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing chat creation with provider...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final chatService = ChatService();
      
      if (!authService.isAuthenticated) {
        setState(() {
          _status = '❌ Not authenticated. Please login first.';
        });
        return;
      }

      // Test with a specific provider ID (you'll need to replace this with a real provider ID)
      // You can get this from the provider list or from the network tab when clicking chat icon
      const testProviderId = '68aec1846022ea3a9c52aa5b'; // Example - replace with real ID
      
      setState(() {
        _status = 'Creating chat with provider ID: $testProviderId...';
      });

      final response = await chatService.createOrGetChat(
        testProviderId,
        serviceName: 'Home Cleaning',
        authService: authService,
      );
      
      if (response['success'] == true) {
        final chat = response['data']['chat'];
        setState(() {
          _status = '✅ Chat created successfully!\nChat ID: ${chat['_id']}\nProvider: ${chat['participant']['name']}';
        });
        
        // Now test if the chat appears in the list
        await Future.delayed(Duration(seconds: 2));
        await _testChatAPI();
      } else {
        setState(() {
          _status = '❌ Chat creation failed: ${response['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Chat creation test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCurrentChats() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing current chats...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!authService.isAuthenticated) {
        setState(() {
          _status = '❌ Not authenticated. Please login first.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/chat/test-chats'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = '✅ Current chats:\nUser ID: ${data['userId']}\nChat count: ${data['chatCount']}\n\n${data['chats'].map((chat) => '• ${chat['participants'].join(' & ')}: ${chat['lastMessage']}').join('\n')}';
        });
      } else {
        setState(() {
          _status = '❌ Failed to get current chats: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Current chats test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testBackendHealth() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing backend health...';
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/chat/test'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = '✅ Backend is healthy!\n${data['message']}\nTimestamp: ${data['timestamp']}';
        });
      } else {
        setState(() {
          _status = '❌ Backend error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Backend connection failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Debug Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat API Debug Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Status: $_status',
                      style: TextStyle(
                        fontSize: 16,
                        color: _status.contains('✅') ? Colors.green : 
                               _status.contains('❌') ? Colors.red : Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isLoading)
                      Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testBackendConnection,
              child: Text('🔗 Test Backend Connection'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthentication,
              child: Text('🔐 Test Authentication'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testChatAPI,
              child: Text('💬 Test Chat API'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateChatWithProvider,
              child: Text('💬 Test Create Chat with Provider'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCurrentChats,
              child: Text('💬 Test Current Chats'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testBackendHealth,
              child: Text('💬 Test Backend Health'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/profile?tab=chats');
              },
              child: Text('📱 Go to Chat Messages'),
            ),
          ],
        ),
      ),
    );
  }
}
