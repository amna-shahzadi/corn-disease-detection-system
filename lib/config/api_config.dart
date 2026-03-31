/// Backend API configuration.
/// Base URL for FYP backend (Swagger: https://fyp-2022.up.railway.app/swagger)
/// If your Swagger shows different paths, update [detectPath] and [historyPath].
class ApiConfig {
  ApiConfig._();

  /// Backend base URL (no trailing slash)
  static const String baseUrl = 'https://fyp-2022.up.railway.app';

  /// Swagger UI URL for reference
  static const String swaggerUrl = '$baseUrl/swagger';

  /// Path for disease detection (POST with multipart "image"). Update to match your backend Swagger.
  /// If you get 404, try: '/predict', '/api/predict', or '/detect'.
  static const String detectPath = '/api/prediction/predict/';

  /// Path for history (GET). Used with /users/history/{user_id}/.
  /// Example: GET /users/history/<user_id>/?page=1
  static const String historyPath = '/users/history';

  /// Path for user registration (POST multipart/form-data).
  static const String registrationPath = '/registeration/';

  /// Path for user login (POST JSON: email, password, returnSecureToken, clientType).
  static const String loginPath = '/login/';

  /// Path for forget password (POST JSON). Use with /forget-password/{email}/.
  static const String forgetPasswordPath = '/forget-password';

  /// New auth endpoints for password reset flow.
  /// Step 1: POST /auth/forgot-password/ with body { "email": "<user_email>" }.
  static const String authForgotPasswordPath = '/auth/forgot-password/';

  /// Step 2: POST /auth/reset-password/ with body
  /// { "email": "<user_email>", "code": "<code>", "new_password": "...", "confirm_password": "..." }.
  static const String authResetPasswordPath = '/auth/reset-password/';

  /// Path for user edit (PUT). Use with /users/edit/{user_id}/.
  static const String userEditPath = '/users/edit';

  /// Path for "own" user edit (PUT). Use with /users/own-update/{user_id}/.
  /// This endpoint accepts a JSON body matching the `UserUpdate` schema from Swagger:
  /// username, location, profile_picture_url (nullable), and remove_profile_picture (boolean).
  static const String userOwnUpdatePath = '/users/own-update';

  /// Path for single user profile (GET). Use with /users/profile/{user_id}/.
  static const String userProfilePath = '/users/profile';

  /// Path for paginated users list (GET). Use with /users/lists/?page=...
  static const String usersListPath = '/users/lists';

  /// Google login via your backend (no Firebase). POST with body { "id_token": "<google_id_token>", "credential": "<google_id_token>" }.
  /// Backend path from Swagger: /login/google/.
  static const String googleLoginPath = '/login/google/';

  /// Optional: Web client ID for Google Sign-In (from Google Cloud Console / backend dev). Leave empty to try default.
  static const String googleWebClientId = '499793187078-86nj5e5c5hoku8n3pgvj9ppn7ulnap8k.apps.googleusercontent.com';

  /// Common timeout for API requests (seconds)
  static const int requestTimeoutSeconds = 60;
}
