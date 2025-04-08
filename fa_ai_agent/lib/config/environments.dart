import 'environment.dart';

const developmentConfig = EnvironmentConfig(
  environment: Environment.development,
  baseUrl: 'https://staging-knkresearchai-server.australia-southeast1.run.app', // Replace with your local development server
  appName: 'KNK Research AI (Dev)',
  enableLogging: true,
);

const stagingConfig = EnvironmentConfig(
  environment: Environment.staging,
  baseUrl: 'https://staging-knkresearchai-server.australia-southeast1.run.app', // Replace with your staging server
  appName: 'KNK Research AI (Staging)',
  enableLogging: true,
);

const productionConfig = EnvironmentConfig(
  environment: Environment.production,
  baseUrl: 'https://knkresearchai-server-1067859590559.australia-southeast1.run.app',
  appName: 'KNK Research AI',
  enableLogging: false,
); 