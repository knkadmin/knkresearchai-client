import 'package:fa_ai_agent/config/environments.dart';

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  final Environment environment;
  final String baseUrl;
  final String appName;
  final bool enableLogging;

  const EnvironmentConfig({
    required this.environment,
    required this.baseUrl,
    required this.appName,
    required this.enableLogging,
  });

  static EnvironmentConfig get current => _current;
  static late EnvironmentConfig _current;

  static void setEnvironment(Environment environment) {
    switch (environment) {
      case Environment.development:
        _current = developmentConfig;
        break;
      case Environment.staging:
        _current = stagingConfig;
        break;
      case Environment.production:
        _current = productionConfig;
        break;
    }
  }
} 