import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../locale_provider.dart';
import 'menu_page.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';



class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _customApiController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  Future<void> _login() async {
    String apiUrl = '';
    try {
      apiUrl = EnvironmentConfig.backendUrl;

      final url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "password": _passwordController.text
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["token"]["accessToken"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MenuPage()),
        );
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.credentialsError;
        });
      }
    } on SocketException {
      setState(() {
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          _errorMessage = localizations.apiError(apiUrl);
        } else {
          _errorMessage = 'An error occurred. AppLocalizations is null';
        }
      });
    } on HttpException {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.serverError(apiUrl);
      });
    } on FormatException {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.formatError(apiUrl);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(AppLocalizations.of(context)!.titleRegLogin),
        ),
        actions: [
          DropdownButton<Locale>(
            value: localeProvider?.locale,
            icon: Icon(Icons.language, color: Colors.white),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                localeProvider?.changeLocale(newLocale);
              }
            },
            items: [
              Locale('en', 'US'),
              Locale('uk', 'UA'),
            ].map<DropdownMenuItem<Locale>>((Locale locale) {
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Text(
                  locale.languageCode == 'en' ? 'English' : 'Українська',
                ),
              );
            }).toList(),
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200]?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<Environment>(
                    value: EnvironmentConfig.currentEnvironment,
                    onChanged: (Environment? newValue) {
                      setState(() {
                        EnvironmentConfig.currentEnvironment = newValue!;
                        if (newValue != Environment.customApi) {
                          _customApiController.clear();
                        }
                      });
                    },
                    items: Environment.values.map<DropdownMenuItem<Environment>>((Environment env) {
                      return DropdownMenuItem<Environment>(
                        value: env,
                        child: Text(env.name),
                      );
                    }).toList(),
                  ),
                  if (EnvironmentConfig.currentEnvironment == Environment.customApi)
                    TextField(
                      controller: _customApiController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.enterCustomAPI,
                        hintText: "http://example.com/api/auth/login",
                      ),
                      onChanged: (value) {
                        EnvironmentConfig.customBackend = value;
                      },
                    ),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.username),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureText,
                  ),
                  SizedBox(height: 10),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  SizedBox(height: 10),
                  ElevatedButton(onPressed: _login, child: Text(AppLocalizations.of(context)!.signIn))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
