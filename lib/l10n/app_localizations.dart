import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Corn Disease Detector'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEmailHint;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginDontHaveAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @loginGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginGoogleSignIn;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signupSubtitle;

  /// No description provided for @signupName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupName;

  /// No description provided for @signupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get signupNameHint;

  /// No description provided for @signupEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmail;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get signupEmailHint;

  /// No description provided for @signupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPassword;

  /// No description provided for @signupPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get signupPasswordHint;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get signupConfirmPasswordHint;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupButton;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signupSignIn;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get dashboardWelcome;

  /// No description provided for @dashboardDetectDisease.
  ///
  /// In en, this message translates to:
  /// **'Detect Disease'**
  String get dashboardDetectDisease;

  /// No description provided for @dashboardCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get dashboardCamera;

  /// No description provided for @dashboardGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get dashboardGallery;

  /// No description provided for @dashboardWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get dashboardWeather;

  /// No description provided for @dashboardHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboardHome;

  /// No description provided for @dashboardProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dashboardProfile;

  /// No description provided for @dashboardHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get dashboardHistory;

  /// No description provided for @dashboardSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboardSettings;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraTitle;

  /// No description provided for @cameraCapturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture Photo'**
  String get cameraCapturePhoto;

  /// No description provided for @cameraSelectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get cameraSelectFromGallery;

  /// No description provided for @cameraNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraNoPermission;

  /// No description provided for @cameraGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get cameraGrantPermission;

  /// No description provided for @cameraProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get cameraProcessing;

  /// No description provided for @cameraAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get cameraAnalyzing;

  /// No description provided for @detectDiseaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get detectDiseaseTitle;

  /// No description provided for @detectDiseaseSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get detectDiseaseSelectImage;

  /// No description provided for @detectDiseaseAnalyzeImage.
  ///
  /// In en, this message translates to:
  /// **'Analyze Image'**
  String get detectDiseaseAnalyzeImage;

  /// No description provided for @detectDiseaseResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get detectDiseaseResult;

  /// No description provided for @detectDiseaseDiseaseName.
  ///
  /// In en, this message translates to:
  /// **'Disease Name'**
  String get detectDiseaseDiseaseName;

  /// No description provided for @detectDiseaseConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get detectDiseaseConfidence;

  /// No description provided for @detectDiseaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detectDiseaseDescription;

  /// No description provided for @detectDiseaseTreatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get detectDiseaseTreatment;

  /// No description provided for @detectDiseaseNoDisease.
  ///
  /// In en, this message translates to:
  /// **'No disease detected'**
  String get detectDiseaseNoDisease;

  /// No description provided for @detectDiseaseHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get detectDiseaseHealthy;

  /// No description provided for @detectDiseaseRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get detectDiseaseRecommendations;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileEnglish;

  /// No description provided for @profileUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get profileUrdu;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherTitle;

  /// No description provided for @weatherCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Weather'**
  String get weatherCurrent;

  /// No description provided for @weatherTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get weatherTemperature;

  /// No description provided for @weatherHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidity;

  /// No description provided for @weatherWindSpeed.
  ///
  /// In en, this message translates to:
  /// **'Wind Speed'**
  String get weatherWindSpeed;

  /// No description provided for @weatherDesc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get weatherDesc;

  /// No description provided for @weatherLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get weatherLocation;

  /// No description provided for @weatherGetting.
  ///
  /// In en, this message translates to:
  /// **'Getting weather data...'**
  String get weatherGetting;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists.'**
  String get errorEmailExists;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get errorInvalidEmail;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorSomethingWentWrong;

  /// No description provided for @errorCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Camera access denied or unavailable.'**
  String get errorCameraAccess;

  /// No description provided for @errorImageProcessing.
  ///
  /// In en, this message translates to:
  /// **'Error processing image. Please try again.'**
  String get errorImageProcessing;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @appBrandName.
  ///
  /// In en, this message translates to:
  /// **'CornCare'**
  String get appBrandName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Identify corn diseases in seconds'**
  String get appTagline;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orText;

  /// No description provided for @dashboardTotalScans.
  ///
  /// In en, this message translates to:
  /// **'Total Scans'**
  String get dashboardTotalScans;

  /// No description provided for @dashboardSinceSignup.
  ///
  /// In en, this message translates to:
  /// **'since signup'**
  String get dashboardSinceSignup;

  /// No description provided for @dashboardLastScan.
  ///
  /// In en, this message translates to:
  /// **'Last Scan'**
  String get dashboardLastScan;

  /// No description provided for @dashboardTipsNews.
  ///
  /// In en, this message translates to:
  /// **'Tips & news'**
  String get dashboardTipsNews;

  /// No description provided for @dashboardWeatherCard.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get dashboardWeatherCard;

  /// No description provided for @dashboardTemp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get dashboardTemp;

  /// No description provided for @dashboardHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get dashboardHumidity;

  /// No description provided for @dashboardLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get dashboardLocation;

  /// No description provided for @dashboardGettingWeather.
  ///
  /// In en, this message translates to:
  /// **'Getting weather...'**
  String get dashboardGettingWeather;

  /// No description provided for @dashboardNoWeatherData.
  ///
  /// In en, this message translates to:
  /// **'No weather data'**
  String get dashboardNoWeatherData;

  /// No description provided for @dashboardHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Scan'**
  String get dashboardHeroTitle;

  /// No description provided for @dashboardHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detect diseases instantly'**
  String get dashboardHeroSubtitle;

  /// No description provided for @dashboardHeroBadge.
  ///
  /// In en, this message translates to:
  /// **'ai detection'**
  String get dashboardHeroBadge;

  /// No description provided for @dashboardHeroMainText.
  ///
  /// In en, this message translates to:
  /// **'Detect corn disease'**
  String get dashboardHeroMainText;

  /// No description provided for @dashboardHeroSubText.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any leaf'**
  String get dashboardHeroSubText;

  /// No description provided for @dashboardSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get dashboardSelectImage;

  /// No description provided for @dashboardCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Camera Access'**
  String get dashboardCameraAccess;

  /// No description provided for @dashboardGalleryAccess.
  ///
  /// In en, this message translates to:
  /// **'Gallery Access'**
  String get dashboardGalleryAccess;

  /// No description provided for @dashboardPermissionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get dashboardPermissionDialogTitle;

  /// No description provided for @dashboardPermissionDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable {permission} permission in Settings to use this feature.'**
  String dashboardPermissionDialogMessage(Object permission);

  /// No description provided for @dashboardPermissionDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dashboardPermissionDialogCancel;

  /// No description provided for @dashboardPermissionDialogSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboardPermissionDialogSettings;

  /// No description provided for @dashboardClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dashboardClose;

  /// No description provided for @cameraRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get cameraRetake;

  /// No description provided for @cameraAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get cameraAnalyze;

  /// No description provided for @cameraCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture image'**
  String get cameraCaptureFailed;

  /// No description provided for @cameraPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get cameraPickFailed;

  /// No description provided for @cameraNoCameras.
  ///
  /// In en, this message translates to:
  /// **'No cameras available'**
  String get cameraNoCameras;

  /// No description provided for @cameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize camera'**
  String get cameraInitFailed;

  /// No description provided for @cameraFlashToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle flash'**
  String get cameraFlashToggleFailed;

  /// No description provided for @detectDiseaseAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Detection Results'**
  String get detectDiseaseAppBarTitle;

  /// No description provided for @detectDiseaseAppBarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Corn leaf analysis'**
  String get detectDiseaseAppBarSubtitle;

  /// No description provided for @detectDiseaseTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select an image'**
  String get detectDiseaseTapToSelect;

  /// No description provided for @detectDiseaseOrUseButtons.
  ///
  /// In en, this message translates to:
  /// **'or use the buttons below'**
  String get detectDiseaseOrUseButtons;

  /// No description provided for @detectDiseaseGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get detectDiseaseGallery;

  /// No description provided for @detectDiseaseCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get detectDiseaseCamera;

  /// No description provided for @detectDiseaseSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get detectDiseaseSummary;

  /// No description provided for @detectDiseaseDetections.
  ///
  /// In en, this message translates to:
  /// **'Detections'**
  String get detectDiseaseDetections;

  /// No description provided for @detectDiseasePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get detectDiseasePrimary;

  /// No description provided for @detectDiseaseConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get detectDiseaseConfidenceLabel;

  /// No description provided for @detectDiseaseSaveResults.
  ///
  /// In en, this message translates to:
  /// **'Save results'**
  String get detectDiseaseSaveResults;

  /// No description provided for @detectDiseaseAnalyzeAnother.
  ///
  /// In en, this message translates to:
  /// **'Analyse another image'**
  String get detectDiseaseAnalyzeAnother;

  /// No description provided for @detectDiseaseSaveComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Save functionality coming soon!'**
  String get detectDiseaseSaveComingSoon;

  /// No description provided for @detectDiseaseUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get detectDiseaseUnknown;

  /// No description provided for @detectDiseaseHealthyLeaf.
  ///
  /// In en, this message translates to:
  /// **'Healthy Leaf'**
  String get detectDiseaseHealthyLeaf;

  /// No description provided for @detectDiseaseDiseaseDetected.
  ///
  /// In en, this message translates to:
  /// **'Disease Detected'**
  String get detectDiseaseDiseaseDetected;

  /// No description provided for @detectDiseaseNoDiseaseDetected.
  ///
  /// In en, this message translates to:
  /// **'No disease detected'**
  String get detectDiseaseNoDiseaseDetected;

  /// No description provided for @detectDiseaseDetectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Disease detected'**
  String get detectDiseaseDetectedStatus;

  /// No description provided for @detectDiseaseObservations.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get detectDiseaseObservations;

  /// No description provided for @detectDiseaseAffectedAreas.
  ///
  /// In en, this message translates to:
  /// **'Affected areas'**
  String get detectDiseaseAffectedAreas;

  /// No description provided for @detectDiseaseHealthyCrop.
  ///
  /// In en, this message translates to:
  /// **'Your crop appears healthy! Continue regular monitoring and maintain good agricultural practices.'**
  String get detectDiseaseHealthyCrop;

  /// No description provided for @detectDiseaseConsultSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Consult with an agricultural extension officer or specialist for tailored treatment recommendations.'**
  String get detectDiseaseConsultSpecialist;

  /// No description provided for @profileAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get profileAccountInfo;

  /// No description provided for @profileAccountInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, email & phone'**
  String get profileAccountInfoSubtitle;

  /// No description provided for @profileFarmInfo.
  ///
  /// In en, this message translates to:
  /// **'Farm Information'**
  String get profileFarmInfo;

  /// No description provided for @profileFarmInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Location & field details'**
  String get profileFarmInfoSubtitle;

  /// No description provided for @profileAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get profileAppSettings;

  /// No description provided for @profileAppSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileAppSettingsSubtitle;

  /// No description provided for @profileEditProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfileButton;

  /// No description provided for @profileSignOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOutButton;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get profileSignOutMessage;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// No description provided for @profileLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocationLabel;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileStatsScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get profileStatsScanned;

  /// No description provided for @profileStatsDiseases.
  ///
  /// In en, this message translates to:
  /// **'Diseases'**
  String get profileStatsDiseases;

  /// No description provided for @profileStatsLastScan.
  ///
  /// In en, this message translates to:
  /// **'Last Scan'**
  String get profileStatsLastScan;

  /// No description provided for @profileToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get profileToday;

  /// No description provided for @profileUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get profileUnknown;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get historyTitle;

  /// No description provided for @historyTotalScans.
  ///
  /// In en, this message translates to:
  /// **'total scans'**
  String get historyTotalScans;

  /// No description provided for @historyLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading history…'**
  String get historyLoading;

  /// No description provided for @historyRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get historyRetry;

  /// No description provided for @historyNoScans.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get historyNoScans;

  /// No description provided for @historyNoHealthyScans.
  ///
  /// In en, this message translates to:
  /// **'No healthy scans'**
  String get historyNoHealthyScans;

  /// No description provided for @historyNoDiseasedScans.
  ///
  /// In en, this message translates to:
  /// **'No diseased scans'**
  String get historyNoDiseasedScans;

  /// No description provided for @historyTotalHealthy.
  ///
  /// In en, this message translates to:
  /// **'Total healthy scans'**
  String get historyTotalHealthy;

  /// No description provided for @historyTotalDiseased.
  ///
  /// In en, this message translates to:
  /// **'Total diseased scans'**
  String get historyTotalDiseased;

  /// No description provided for @historyStartScanning.
  ///
  /// In en, this message translates to:
  /// **'Start scanning leaves to see your detection history here.'**
  String get historyStartScanning;

  /// No description provided for @tipRotateCropsAnnually.
  ///
  /// In en, this message translates to:
  /// **'Rotate crops annually'**
  String get tipRotateCropsAnnually;

  /// No description provided for @tipRotateCropsAnnuallyDesc.
  ///
  /// In en, this message translates to:
  /// **'Rotating crops prevents soil depletion and reduces pest buildup.'**
  String get tipRotateCropsAnnuallyDesc;

  /// No description provided for @tipNewPestResistantCorn.
  ///
  /// In en, this message translates to:
  /// **'New pest-resistant corn'**
  String get tipNewPestResistantCorn;

  /// No description provided for @tipNewPestResistantCornDesc.
  ///
  /// In en, this message translates to:
  /// **'Scientists developed a variety resistant to common pests.'**
  String get tipNewPestResistantCornDesc;

  /// No description provided for @tipHarvestSeasonComing.
  ///
  /// In en, this message translates to:
  /// **'Harvest season coming!'**
  String get tipHarvestSeasonComing;

  /// No description provided for @tipHarvestSeasonComingDesc.
  ///
  /// In en, this message translates to:
  /// **'Prepare your equipment for the upcoming harvest season.'**
  String get tipHarvestSeasonComingDesc;

  /// No description provided for @tipMultanYieldTrials.
  ///
  /// In en, this message translates to:
  /// **'Multan yield trials'**
  String get tipMultanYieldTrials;

  /// No description provided for @tipMultanYieldTrialsDesc.
  ///
  /// In en, this message translates to:
  /// **'High-yield trials show 15% improvement with new irrigation.'**
  String get tipMultanYieldTrialsDesc;

  /// No description provided for @tipMultanCottonMaizeRotation.
  ///
  /// In en, this message translates to:
  /// **'Multan cotton-maize rotation'**
  String get tipMultanCottonMaizeRotation;

  /// No description provided for @tipMultanCottonMaizeRotationDesc.
  ///
  /// In en, this message translates to:
  /// **'Alternate cotton and maize for better soil health in Multan region.'**
  String get tipMultanCottonMaizeRotationDesc;

  /// No description provided for @tipMultanHeatWarning.
  ///
  /// In en, this message translates to:
  /// **'Multan heat warning'**
  String get tipMultanHeatWarning;

  /// No description provided for @tipMultanHeatWarningDesc.
  ///
  /// In en, this message translates to:
  /// **'Extreme heat expected - protect young maize plants.'**
  String get tipMultanHeatWarningDesc;

  /// No description provided for @tipSoilTestingReminder.
  ///
  /// In en, this message translates to:
  /// **'Soil testing reminder'**
  String get tipSoilTestingReminder;

  /// No description provided for @tipSoilTestingReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Test your soil before kharif for better fertilizer use.'**
  String get tipSoilTestingReminderDesc;

  /// No description provided for @tipLahoreAgricultureExpo.
  ///
  /// In en, this message translates to:
  /// **'Lahore agriculture expo'**
  String get tipLahoreAgricultureExpo;

  /// No description provided for @tipLahoreAgricultureExpoDesc.
  ///
  /// In en, this message translates to:
  /// **'Modern farming equipment showcase next month.'**
  String get tipLahoreAgricultureExpoDesc;

  /// No description provided for @tipLahorePestControl.
  ///
  /// In en, this message translates to:
  /// **'Lahore pest control'**
  String get tipLahorePestControl;

  /// No description provided for @tipLahorePestControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitor for armyworm in Lahore district maize fields.'**
  String get tipLahorePestControlDesc;

  /// No description provided for @tipFaisalabadMandiRates.
  ///
  /// In en, this message translates to:
  /// **'Faisalabad mandi rates'**
  String get tipFaisalabadMandiRates;

  /// No description provided for @tipFaisalabadMandiRatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Corn prices are stable — good time to plan harvest sales.'**
  String get tipFaisalabadMandiRatesDesc;

  /// No description provided for @tipFaisalabadResearchCenter.
  ///
  /// In en, this message translates to:
  /// **'Faisalabad research center'**
  String get tipFaisalabadResearchCenter;

  /// No description provided for @tipFaisalabadResearchCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'New maize varieties developed for local conditions.'**
  String get tipFaisalabadResearchCenterDesc;

  /// No description provided for @tipFaisalabadFertilizerTips.
  ///
  /// In en, this message translates to:
  /// **'Faisalabad fertilizer tips'**
  String get tipFaisalabadFertilizerTips;

  /// No description provided for @tipFaisalabadFertilizerTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced NPK application recommended for Faisalabad soils.'**
  String get tipFaisalabadFertilizerTipsDesc;

  /// No description provided for @tipRawalpindiSowingTime.
  ///
  /// In en, this message translates to:
  /// **'Rawalpindi sowing time'**
  String get tipRawalpindiSowingTime;

  /// No description provided for @tipRawalpindiSowingTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Start maize sowing in March for optimal yield in Potohar region.'**
  String get tipRawalpindiSowingTimeDesc;

  /// No description provided for @tipRawalpindiFarmingSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Rawalpindi farming subsidy'**
  String get tipRawalpindiFarmingSubsidy;

  /// No description provided for @tipRawalpindiFarmingSubsidyDesc.
  ///
  /// In en, this message translates to:
  /// **'Govt announces subsidy for maize farmers in northern Punjab.'**
  String get tipRawalpindiFarmingSubsidyDesc;

  /// No description provided for @tipRawalpindiWeatherAlert.
  ///
  /// In en, this message translates to:
  /// **'Rawalpindi weather alert'**
  String get tipRawalpindiWeatherAlert;

  /// No description provided for @tipRawalpindiWeatherAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Unseasonal rains may affect maize germination.'**
  String get tipRawalpindiWeatherAlertDesc;

  /// No description provided for @tipGujranwalaGrainMarket.
  ///
  /// In en, this message translates to:
  /// **'Gujranwala grain market'**
  String get tipGujranwalaGrainMarket;

  /// No description provided for @tipGujranwalaGrainMarketDesc.
  ///
  /// In en, this message translates to:
  /// **'Maize prices rising due to increased demand.'**
  String get tipGujranwalaGrainMarketDesc;

  /// No description provided for @tipGujranwalaSoilHealth.
  ///
  /// In en, this message translates to:
  /// **'Gujranwala soil health'**
  String get tipGujranwalaSoilHealth;

  /// No description provided for @tipGujranwalaSoilHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Add organic matter to improve Gujranwala soil structure.'**
  String get tipGujranwalaSoilHealthDesc;

  /// No description provided for @tipGujranwalaPestAlert.
  ///
  /// In en, this message translates to:
  /// **'Gujranwala pest alert'**
  String get tipGujranwalaPestAlert;

  /// No description provided for @tipGujranwalaPestAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Fall armyworm detected - take preventive measures.'**
  String get tipGujranwalaPestAlertDesc;

  /// No description provided for @tipSahiwalWaterManagement.
  ///
  /// In en, this message translates to:
  /// **'Sahiwal water management'**
  String get tipSahiwalWaterManagement;

  /// No description provided for @tipSahiwalWaterManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Use drip irrigation for maize to save water and improve yield.'**
  String get tipSahiwalWaterManagementDesc;

  /// No description provided for @tipSahiwalAgricultureFair.
  ///
  /// In en, this message translates to:
  /// **'Sahiwal agriculture fair'**
  String get tipSahiwalAgricultureFair;

  /// No description provided for @tipSahiwalAgricultureFairDesc.
  ///
  /// In en, this message translates to:
  /// **'Annual farming fair starts next week with maize focus.'**
  String get tipSahiwalAgricultureFairDesc;

  /// No description provided for @tipSahiwalHybridVarieties.
  ///
  /// In en, this message translates to:
  /// **'Sahiwal hybrid varieties'**
  String get tipSahiwalHybridVarieties;

  /// No description provided for @tipSahiwalHybridVarietiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Try new hybrid varieties adapted for Sahiwal climate.'**
  String get tipSahiwalHybridVarietiesDesc;

  /// No description provided for @tipSargodhaCitrusMaize.
  ///
  /// In en, this message translates to:
  /// **'Sargodha citrus-maize'**
  String get tipSargodhaCitrusMaize;

  /// No description provided for @tipSargodhaCitrusMaizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Intercropping maize with citrus shows promising results.'**
  String get tipSargodhaCitrusMaizeDesc;

  /// No description provided for @tipSargodhaIrrigationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Sargodha irrigation schedule'**
  String get tipSargodhaIrrigationSchedule;

  /// No description provided for @tipSargodhaIrrigationScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'Optimize irrigation for Sargodha\'s water conditions.'**
  String get tipSargodhaIrrigationScheduleDesc;

  /// No description provided for @tipSargodhaFertilizerShortage.
  ///
  /// In en, this message translates to:
  /// **'Sargodha fertilizer shortage'**
  String get tipSargodhaFertilizerShortage;

  /// No description provided for @tipSargodhaFertilizerShortageDesc.
  ///
  /// In en, this message translates to:
  /// **'Urea shortage reported - plan fertilizer purchases early.'**
  String get tipSargodhaFertilizerShortageDesc;

  /// No description provided for @tipBahawalpurSeedSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Bahawalpur seed subsidy'**
  String get tipBahawalpurSeedSubsidy;

  /// No description provided for @tipBahawalpurSeedSubsidyDesc.
  ///
  /// In en, this message translates to:
  /// **'Govt seed subsidy for cotton and maize available now.'**
  String get tipBahawalpurSeedSubsidyDesc;

  /// No description provided for @tipBahawalpurDesertFarming.
  ///
  /// In en, this message translates to:
  /// **'Bahawalpur desert farming'**
  String get tipBahawalpurDesertFarming;

  /// No description provided for @tipBahawalpurDesertFarmingDesc.
  ///
  /// In en, this message translates to:
  /// **'Drought-resistant maize varieties recommended for Bahawalpur.'**
  String get tipBahawalpurDesertFarmingDesc;

  /// No description provided for @tipBahawalpurWaterCrisis.
  ///
  /// In en, this message translates to:
  /// **'Bahawalpur water crisis'**
  String get tipBahawalpurWaterCrisis;

  /// No description provided for @tipBahawalpurWaterCrisisDesc.
  ///
  /// In en, this message translates to:
  /// **'Groundwater levels dropping - adopt water conservation.'**
  String get tipBahawalpurWaterCrisisDesc;

  /// No description provided for @tipRahimYarKhanSugarMill.
  ///
  /// In en, this message translates to:
  /// **'Rahim Yar Khan sugar mill'**
  String get tipRahimYarKhanSugarMill;

  /// No description provided for @tipRahimYarKhanSugarMillDesc.
  ///
  /// In en, this message translates to:
  /// **'New sugar mill increases maize demand in the region.'**
  String get tipRahimYarKhanSugarMillDesc;

  /// No description provided for @tipRahimYarKhanSowingTips.
  ///
  /// In en, this message translates to:
  /// **'Rahim Yar Khan sowing tips'**
  String get tipRahimYarKhanSowingTips;

  /// No description provided for @tipRahimYarKhanSowingTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Early sowing recommended for Rahim Yar Khan climate.'**
  String get tipRahimYarKhanSowingTipsDesc;

  /// No description provided for @tipRahimYarKhanFloodRisk.
  ///
  /// In en, this message translates to:
  /// **'Rahim Yar Khan flood risk'**
  String get tipRahimYarKhanFloodRisk;

  /// No description provided for @tipRahimYarKhanFloodRiskDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitor flood warnings during monsoon season.'**
  String get tipRahimYarKhanFloodRiskDesc;

  /// No description provided for @tipDGKhanAgricultureCollege.
  ///
  /// In en, this message translates to:
  /// **'DG Khan agriculture college'**
  String get tipDGKhanAgricultureCollege;

  /// No description provided for @tipDGKhanAgricultureCollegeDesc.
  ///
  /// In en, this message translates to:
  /// **'New research on maize disease resistance published.'**
  String get tipDGKhanAgricultureCollegeDesc;

  /// No description provided for @tipDGKhanHillyTerrain.
  ///
  /// In en, this message translates to:
  /// **'DG Khan hilly terrain'**
  String get tipDGKhanHillyTerrain;

  /// No description provided for @tipDGKhanHillyTerrainDesc.
  ///
  /// In en, this message translates to:
  /// **'Use contour farming for maize on DG Khan slopes.'**
  String get tipDGKhanHillyTerrainDesc;

  /// No description provided for @tipDGKhanDroughtWarning.
  ///
  /// In en, this message translates to:
  /// **'DG Khan drought warning'**
  String get tipDGKhanDroughtWarning;

  /// No description provided for @tipDGKhanDroughtWarningDesc.
  ///
  /// In en, this message translates to:
  /// **'Below-average rainfall expected - plan accordingly.'**
  String get tipDGKhanDroughtWarningDesc;

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyFilterHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get historyFilterHealthy;

  /// No description provided for @historyFilterDiseased.
  ///
  /// In en, this message translates to:
  /// **'Diseased'**
  String get historyFilterDiseased;

  /// No description provided for @historyFilterSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get historyFilterSortTitle;

  /// No description provided for @historyFilterByLabel.
  ///
  /// In en, this message translates to:
  /// **'FILTER BY'**
  String get historyFilterByLabel;

  /// No description provided for @historySortByLabel.
  ///
  /// In en, this message translates to:
  /// **'SORT BY DATE'**
  String get historySortByLabel;

  /// No description provided for @historyShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get historyShowAll;

  /// No description provided for @historyHealthyOnly.
  ///
  /// In en, this message translates to:
  /// **'Healthy Only'**
  String get historyHealthyOnly;

  /// No description provided for @historyDiseaseOnly.
  ///
  /// In en, this message translates to:
  /// **'Disease Only'**
  String get historyDiseaseOnly;

  /// No description provided for @historyNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get historyNewestFirst;

  /// No description provided for @dashboardScrollForMore.
  ///
  /// In en, this message translates to:
  /// **'scroll for more →'**
  String get dashboardScrollForMore;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardJanuary.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get dashboardJanuary;

  /// No description provided for @dashboardFebruary.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get dashboardFebruary;

  /// No description provided for @dashboardMarch.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get dashboardMarch;

  /// No description provided for @dashboardApril.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get dashboardApril;

  /// No description provided for @dashboardMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get dashboardMay;

  /// No description provided for @dashboardJune.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get dashboardJune;

  /// No description provided for @dashboardJuly.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get dashboardJuly;

  /// No description provided for @dashboardAugust.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get dashboardAugust;

  /// No description provided for @dashboardSeptember.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get dashboardSeptember;

  /// No description provided for @dashboardOctober.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get dashboardOctober;

  /// No description provided for @dashboardNovember.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get dashboardNovember;

  /// No description provided for @dashboardDecember.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dashboardDecember;

  /// No description provided for @historyOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get historyOldestFirst;

  /// No description provided for @historyHealthyBadge.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get historyHealthyBadge;

  /// No description provided for @historyDiseaseBadge.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get historyDiseaseBadge;

  /// No description provided for @historyUserNotIdentified.
  ///
  /// In en, this message translates to:
  /// **'User not identified for history.'**
  String get historyUserNotIdentified;

  /// No description provided for @historyFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get historyFailedToLoad;

  /// No description provided for @historyDetailConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get historyDetailConfidence;

  /// No description provided for @historyDetailSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get historyDetailSeverity;

  /// No description provided for @historySevere.
  ///
  /// In en, this message translates to:
  /// **'severe'**
  String get historySevere;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Try email & password.'**
  String get googleSignInFailed;

  /// No description provided for @googleSignInFailedError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInFailedError;

  /// No description provided for @signedInSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get signedInSuccessfully;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get forgotPasswordVerificationTitle;

  /// No description provided for @forgotPasswordVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email.'**
  String get forgotPasswordVerificationSubtitle;

  /// No description provided for @forgotPasswordCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get forgotPasswordCodeHint;

  /// No description provided for @forgotPasswordContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get forgotPasswordContinue;

  /// No description provided for @forgotPasswordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordResetTitle;

  /// No description provided for @forgotPasswordResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account.'**
  String get forgotPasswordResetSubtitle;

  /// No description provided for @forgotPasswordNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get forgotPasswordNewPasswordHint;

  /// No description provided for @forgotPasswordConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get forgotPasswordConfirmPasswordHint;

  /// No description provided for @forgotPasswordSaveNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Save New Password'**
  String get forgotPasswordSaveNewPassword;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @forgotPasswordPleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get forgotPasswordPleaseEnterEmail;

  /// No description provided for @forgotPasswordPleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get forgotPasswordPleaseEnterValidEmail;

  /// No description provided for @forgotPasswordCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code has been sent to your email'**
  String get forgotPasswordCodeSent;

  /// No description provided for @forgotPasswordPleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code sent to your email'**
  String get forgotPasswordPleaseEnterCode;

  /// No description provided for @forgotPasswordPleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter and confirm your new password'**
  String get forgotPasswordPleaseEnterPassword;

  /// No description provided for @forgotPasswordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password has been reset successfully'**
  String get forgotPasswordResetSuccess;

  /// No description provided for @forgotPasswordFailedToSendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get forgotPasswordFailedToSendCode;

  /// No description provided for @forgotPasswordFailedToReset.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get forgotPasswordFailedToReset;

  /// No description provided for @forgotPasswordPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get forgotPasswordPasswordRequired;

  /// No description provided for @forgotPasswordPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get forgotPasswordPasswordMinLength;

  /// No description provided for @forgotPasswordPasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet requirements'**
  String get forgotPasswordPasswordRequirements;

  /// No description provided for @forgotPasswordPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get forgotPasswordPasswordsDoNotMatch;

  /// No description provided for @forgotPasswordAtLeast8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get forgotPasswordAtLeast8Chars;

  /// No description provided for @forgotPasswordOneUppercase.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get forgotPasswordOneUppercase;

  /// No description provided for @forgotPasswordOneLowercase.
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter'**
  String get forgotPasswordOneLowercase;

  /// No description provided for @forgotPasswordOneNumber.
  ///
  /// In en, this message translates to:
  /// **'One number'**
  String get forgotPasswordOneNumber;

  /// No description provided for @forgotPasswordOneSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'One special character'**
  String get forgotPasswordOneSpecialChar;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join our farming community today'**
  String get signUpSubtitle;

  /// No description provided for @signUpFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get signUpFullNameHint;

  /// No description provided for @signUpEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get signUpEmailHint;

  /// No description provided for @signUpPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get signUpPhoneHint;

  /// No description provided for @signUpPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signUpPasswordHint;

  /// No description provided for @signUpConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signUpConfirmPasswordHint;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @signUpOrText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get signUpOrText;

  /// No description provided for @signUpGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpGoogleSignIn;

  /// No description provided for @signUpHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signUpHaveAccount;

  /// No description provided for @signUpSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signUpSignIn;

  /// No description provided for @signUpPleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get signUpPleaseEnterFullName;

  /// No description provided for @signUpEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get signUpEmailRequired;

  /// No description provided for @signUpValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get signUpValidEmail;

  /// No description provided for @signUpPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get signUpPasswordRequired;

  /// No description provided for @signUpPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get signUpPasswordMinLength;

  /// No description provided for @signUpPasswordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain an uppercase letter'**
  String get signUpPasswordUppercase;

  /// No description provided for @signUpPasswordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a lowercase letter'**
  String get signUpPasswordLowercase;

  /// No description provided for @signUpPasswordNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a number'**
  String get signUpPasswordNumber;

  /// No description provided for @signUpPasswordSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a special character'**
  String get signUpPasswordSpecialChar;

  /// No description provided for @signUpPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signUpPasswordsDoNotMatch;

  /// No description provided for @signUpRegistrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Registration successful! Account created.'**
  String get signUpRegistrationSuccess;

  /// No description provided for @signUpGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled'**
  String get signUpGoogleCancelled;

  /// No description provided for @signUpGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Try email & password.'**
  String get signUpGoogleFailed;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get signUpFailed;

  /// No description provided for @signUpServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. If you\'re on web, the backend may need to allow this origin (CORS).'**
  String get signUpServerUnreachable;

  /// No description provided for @signUpGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get signUpGoogleSignInFailed;

  /// No description provided for @signUpSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get signUpSignedIn;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editProfileSave;

  /// No description provided for @editProfileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSaveChanges;

  /// No description provided for @editProfileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editProfileCancel;

  /// No description provided for @editProfileTapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get editProfileTapToChangePhoto;

  /// No description provided for @editProfilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get editProfilePersonalInfo;

  /// No description provided for @editProfileFarmInfo.
  ///
  /// In en, this message translates to:
  /// **'FARM INFORMATION'**
  String get editProfileFarmInfo;

  /// No description provided for @editProfileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get editProfileFullNameLabel;

  /// No description provided for @editProfileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileEmailLabel;

  /// No description provided for @editProfilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editProfilePhoneLabel;

  /// No description provided for @editProfileFarmLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm Location'**
  String get editProfileFarmLocationLabel;

  /// No description provided for @editProfileFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get editProfileFullNameHint;

  /// No description provided for @editProfileEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get editProfileEmailHint;

  /// No description provided for @editProfilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'03XXXXXXXXX'**
  String get editProfilePhoneHint;

  /// No description provided for @editProfileUpdatePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Photo'**
  String get editProfileUpdatePhotoTitle;

  /// No description provided for @editProfileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get editProfileTakePhoto;

  /// No description provided for @editProfileChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get editProfileChooseFromGallery;

  /// No description provided for @editProfileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get editProfileRemovePhoto;

  /// No description provided for @editProfileSelectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select District'**
  String get editProfileSelectDistrict;

  /// No description provided for @editProfileFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get editProfileFullNameRequired;

  /// No description provided for @editProfileFarmLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Farm location is required'**
  String get editProfileFarmLocationRequired;

  /// No description provided for @editProfileUserNotIdentified.
  ///
  /// In en, this message translates to:
  /// **'User not identified — please log in again'**
  String get editProfileUserNotIdentified;

  /// No description provided for @editProfileProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileProfileUpdated;

  /// No description provided for @editProfileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get editProfileUpdateFailed;

  /// No description provided for @editProfileCouldNotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get editProfileCouldNotLoadImage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ur': return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
