import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({Key? key}) : super(key: key);

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'client';
  bool _isLoading = false;
  String _result = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing login...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _result = 'Login Result:\n${response.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Login Error:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testRegister() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing registration...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        role: _selectedRole,
      );

      setState(() {
        _result = 'Registration Result:\n${response.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Registration Error:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testValidateToken() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing token validation...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.validateToken();

      setState(() {
        _result = 'Token Validation Result:\n$response';
      });
    } catch (e) {
      setState(() {
        _result = 'Token Validation Error:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogout() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing logout...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();

      setState(() {
        _result = 'Logout successful';
      });
    } catch (e) {
      setState(() {
        _result = 'Logout Error:\n$e';
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
        title: const Text('Auth Test Screen'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Registration Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registration Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'client', child: Text('Client')),
                          DropdownMenuItem(value: 'provider', child: Text('Provider')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testRegister,
                        child: const Text('Test Registration'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Login Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testLogin,
                        child: const Text('Test Login'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Token Validation and Logout
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Token Operations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _testValidateToken,
                              child: const Text('Validate Token'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _testLogout,
                              child: const Text('Logout'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Current Auth Status
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Auth Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Is Authenticated: ${authService.isAuthenticated}'),
                          Text('User Role: ${authService.userRole ?? 'None'}'),
                          Text('User Name: ${authService.userFullName}'),
                          Text('Is Admin: ${authService.isAdmin}'),
                          Text('Is Provider: ${authService.isProvider}'),
                          Text('Is Client: ${authService.isClient}'),
                          Text('Is Verified: ${authService.isVerified}'),
                          Text('Is Active: ${authService.isActive}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Results
              if (_result.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 