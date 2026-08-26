class ApiConfig {
  // Example: 'http://192.168.0.159:8000'
  // Use 'http://10.0.2.2:8000' for Android Emulator
  // Use 'http://127.0.0.1:8000' for iOS Simulator
  // Set the base URL for the API here.
  // This can be easily changed depending on the environment (dev, staging, prod)
  //static const String baseUrl = 'http://192.168.0.66:8000';
  static const String baseUrl = 'https://toolhubbackend.naiyo24.com';
  //static const String baseUrl = 'https://backend.toolhubutility.com';

  static const String appName = 'ToolHub';
  
  // LoanDesk backend base URL (FastAPI)
  static const String loanDeskBaseUrl = baseUrl;
}
