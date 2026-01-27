import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/api_server_helper.dart';
import '../../helpers/api_server_type.dart';
import '../../helpers/app_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../locale/locale_provider.dart';
import '../about_app_dialog.dart';
import '../menu_page.dart';
import '../usr_wifi/provision/usr_provision_page.dart';
import 'login_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _customApiController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final data = await LoginHelper.getAuth();
    setState(() {
      _usernameController.text = data[LoginHelper.kUser] ?? '';
      _passwordController.text = data[LoginHelper.kPass] ?? '';
      _customApiController.text = data[LoginHelper.kCustom] ?? '';

      if (data[LoginHelper.kEnv] != null) {
        if (data[LoginHelper.kEnv] == ApiServerType.customApi.name) {
          ApiServerHelper.currentEnvironment = ApiServerType.customApi;
          ApiServerHelper.customBackend = _customApiController.text;
        } else {
          ApiServerHelper.currentEnvironment = ApiServerType.values.firstWhere(
                (e) => e.name == data[LoginHelper.kEnv],
            orElse: () => ApiServerType.localHostHome,
          );
        }
      }
    });
  }

  Future<void> _login() async {
    String apiUrl = '';
    try {
      apiUrl = ApiServerHelper.backendUrl + AppHelper.apiPathLogin;

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
        await LoginHelper.saveAuth(
          _usernameController.text,
          _passwordController.text,
          ApiServerHelper.currentEnvironment.name,
          _customApiController.text,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MenuPage()),
        );
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.credentialsError;
        });
      }
    } catch (e) {
      // ПРАВИЛЬНА ОБРОБКА ПОМИЛОК БЕЗ DART:IO
      setState(() {
        final localizations = AppLocalizations.of(context);
        String errorStr = e.toString().toLowerCase();

        if (errorStr.contains('socketexception')) {
          _errorMessage = localizations?.apiError(apiUrl) ?? 'Socket Error';
        } else if (errorStr.contains('httpexception')) {
          _errorMessage = localizations?.serverError(apiUrl) ?? 'HTTP Error';
        } else if (e is FormatException) {
          _errorMessage = localizations?.formatError(apiUrl) ?? 'Format Error';
        } else {
          _errorMessage = e.toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.wifi_find, color: Colors.blue),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UsrProvisionPage(),
              ),
            );
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.titleRegLogin,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const AboutAppDialog(),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.more_vert),
            onSelected: (Locale newLocale) {
              localeProvider?.changeLocale(newLocale);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Locale('uk', 'UA'),
                child: Text('Українська'),
              ),
              const PopupMenuItem(
                value: Locale('en', 'US'),
                child: Text('English'),
              ),
            ],
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
                color: Colors.grey[200]?.withAlpha((0.9 * 255).toInt()),
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
                  DropdownButton<ApiServerType>(
                    value: ApiServerHelper.currentEnvironment,
                    onChanged: (ApiServerType? newValue) {
                      setState(() {
                        ApiServerHelper.currentEnvironment = newValue!;
                        if (newValue != ApiServerType.customApi) {
                          _customApiController.clear();
                        }
                      });
                    },
                    items: ApiServerType.values.map<DropdownMenuItem<ApiServerType>>((ApiServerType env) {
                      return DropdownMenuItem<ApiServerType>(
                        value: env,
                        child: Text(env.name),
                      );
                    }).toList(),
                  ),
                  if (ApiServerHelper.currentEnvironment == ApiServerType.customApi)
                    TextField(
                      controller: _customApiController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.enterCustomAPI,
                        hintText: "http://example.com/api/auth/login",
                      ),
                      onChanged: (value) {
                        ApiServerHelper.customBackend = value;
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