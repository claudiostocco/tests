/// Exception thrown when API request fails.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Interface for API network operations.
abstract class ApiService {
  Future<void> sendJsonPayload(String jsonPayload);
}

/// Simulated implementation of [ApiService] for sending JSON data to a REST API.
class ApiServiceImpl implements ApiService {
  final Duration simulationDelay;

  const ApiServiceImpl({
    this.simulationDelay = const Duration(seconds: 2),
  });

  @override
  Future<void> sendJsonPayload(String jsonPayload) async {
    // Simulate network delay
    await Future.delayed(simulationDelay);

    if (jsonPayload.trim().isEmpty) {
      throw const ApiException('Cannot send empty payload to API.');
    }

    // Network request success simulation
    return;
  }
}
