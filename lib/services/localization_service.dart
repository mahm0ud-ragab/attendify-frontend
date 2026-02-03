// Localization Service - Manages app translations
// Path: lib/services/localization_service.dart

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Static accessor for easy access throughout the app
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Delegate for loading localization
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  // Translation maps for each supported language
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _enTranslations,
    'ar': _arTranslations,
    'fr': _frTranslations,
    'es': _esTranslations,
    'de': _deTranslations,
  };

  // Get translated string
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for common translations

  // Settings Screen
  String get settings => translate('settings');
  String get general => translate('general');
  String get notifications => translate('notifications');
  String get notificationsSubtitle => translate('notifications_subtitle');
  String get biometricLogin => translate('biometric_login');
  String get biometricSubtitle => translate('biometric_subtitle');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get support => translate('support');
  String get helpCenter => translate('help_center');
  String get reportIssue => translate('report_issue');
  String get aboutApp => translate('about_app');
  String get logout => translate('logout');
  String get logoutConfirm => translate('logout_confirm');
  String get cancel => translate('cancel');
  String get version => translate('version');

  // Common
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');

  // Dashboard
  String get dashboard => translate('dashboard');
  String get attendance => translate('attendance');
  String get profile => translate('profile');
  String get schedule => translate('schedule');
  String get courses => translate('courses');

  // Authentication
  String get login => translate('login');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get dontHaveAccount => translate('dont_have_account');
  String get signUp => translate('sign_up');
  String get alreadyHaveAccount => translate('already_have_account');

  // Add these inside the AppLocalizations class
  String get qrScannerTitle => translate('qr_scanner_title');
  String get scannerInstruction => translate('scanner_instruction');
  String get processing => translate('processing');
  String get attendanceMarked => translate('attendance_marked');

}

// English Translations
const Map<String, String> _enTranslations = {
  // Settings
  'settings': 'Settings',
  'general': 'GENERAL',
  'notifications': 'Notifications',
  'notifications_subtitle': 'Receive attendance alerts',
  'biometric_login': 'Biometric Login',
  'biometric_subtitle': 'Use FaceID / Fingerprint',
  'language': 'Language',
  'select_language': 'Select Language',
  'support': 'SUPPORT',
  'help_center': 'Help Center',
  'report_issue': 'Report an Issue',
  'about_app': 'About Attendify',
  'logout': 'Logout',
  'logoutConfirm': 'Are you sure you want to log out?',
  'cancel': 'Cancel',
  'version': 'Version',

  // Common
  'ok': 'OK',
  'yes': 'Yes',
  'no': 'No',
  'save': 'Save',
  'edit': 'Edit',
  'delete': 'Delete',
  'back': 'Back',
  'next': 'Next',
  'done': 'Done',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',

  // Dashboard
  'dashboard': 'Dashboard',
  'attendance': 'Attendance',
  'profile': 'Profile',
  'schedule': 'Schedule',
  'courses': 'Courses',

  // Authentication
  'login': 'Login',
  'email': 'Email',
  'password': 'Password',
  'forgot_password': 'Forgot Password?',
  'dont_have_account': "Don't have an account?",
  'sign_up': 'Sign Up',
  'already_have_account': 'Already have an account?',
  // qr generator
  'qr_generator_title': 'QR Generator',
  'scan_to_mark': 'Scan to Mark Attendance',
  'attendance_session': 'Attendance Session',
  'refreshing_in': 'Refreshing in',
  'qr_scanner_title': 'QR Scanner',
};

// Arabic Translations (RTL)
const Map<String, String> _arTranslations = {
  // Settings
  'settings': 'الإعدادات',
  'general': 'عام',
  'notifications': 'الإشعارات',
  'notifications_subtitle': 'استقبال تنبيهات الحضور',
  'biometric_login': 'تسجيل الدخول البيومتري',
  'biometric_subtitle': 'استخدام البصمة أو التعرف على الوجه',
  'language': 'اللغة',
  'select_language': 'اختر اللغة',
  'support': 'الدعم',
  'help_center': 'مركز المساعدة',
  'report_issue': 'الإبلاغ عن مشكلة',
  'about_app': 'حول Attendify',
  'logout': 'تسجيل الخروج',
  'logoutConfirm': 'هل أنت متأكد من تسجيل الخروج؟',
  'cancel': 'إلغاء',
  'version': 'الإصدار',

  // Common
  'ok': 'موافق',
  'yes': 'نعم',
  'no': 'لا',
  'save': 'حفظ',
  'edit': 'تعديل',
  'delete': 'حذف',
  'back': 'رجوع',
  'next': 'التالي',
  'done': 'تم',
  'loading': 'جاري التحميل...',
  'error': 'خطأ',
  'success': 'نجح',

  // Dashboard
  'dashboard': 'لوحة التحكم',
  'attendance': 'الحضور',
  'profile': 'الملف الشخصي',
  'schedule': 'الجدول',
  'courses': 'المقررات',

  // Authentication
  'login': 'تسجيل الدخول',
  'email': 'البريد الإلكتروني',
  'password': 'كلمة المرور',
  'forgot_password': 'نسيت كلمة المرور؟',
  'dont_have_account': 'ليس لديك حساب؟',
  'sign_up': 'إنشاء حساب',
  'already_have_account': 'لديك حساب بالفعل؟',

  //qr generator
  'qr_generator_title': 'مولد الرمز',
  'scan_to_mark': 'امسح لتسجيل الحضور',
  'attendance_session': 'جلسة الحضور',
  'refreshing_in': 'تحديث خلال',
  'qr_scanner_title': 'ماسح الرمز',
};

// French Translations
const Map<String, String> _frTranslations = {
  // Settings
  'settings': 'Paramètres',
  'general': 'GÉNÉRAL',
  'notifications': 'Notifications',
  'notifications_subtitle': 'Recevoir des alertes de présence',
  'biometric_login': 'Connexion biométrique',
  'biometric_subtitle': 'Utiliser FaceID / Empreinte',
  'language': 'Langue',
  'select_language': 'Sélectionner la langue',
  'support': 'SUPPORT',
  'help_center': "Centre d'aide",
  'report_issue': 'Signaler un problème',
  'about_app': 'À propos de Attendify',
  'logout': 'Déconnexion',
  'logoutConfirm': 'Êtes-vous sûr de vouloir vous déconnecter?',
  'cancel': 'Annuler',
  'version': 'Version',

  // Common
  'ok': 'OK',
  'yes': 'Oui',
  'no': 'Non',
  'save': 'Enregistrer',
  'edit': 'Modifier',
  'delete': 'Supprimer',
  'back': 'Retour',
  'next': 'Suivant',
  'done': 'Terminé',
  'loading': 'Chargement...',
  'error': 'Erreur',
  'success': 'Succès',

  // Dashboard
  'dashboard': 'Tableau de bord',
  'attendance': 'Présence',
  'profile': 'Profil',
  'schedule': 'Horaire',
  'courses': 'Cours',

  // Authentication
  'login': 'Connexion',
  'email': 'Email',
  'password': 'Mot de passe',
  'forgot_password': 'Mot de passe oublié?',
  'dont_have_account': "Vous n'avez pas de compte?",
  'sign_up': "S'inscrire",
  'already_have_account': 'Vous avez déjà un compte?',
};

// Spanish Translations
const Map<String, String> _esTranslations = {
  // Settings
  'settings': 'Configuración',
  'general': 'GENERAL',
  'notifications': 'Notificaciones',
  'notifications_subtitle': 'Recibir alertas de asistencia',
  'biometric_login': 'Inicio biométrico',
  'biometric_subtitle': 'Usar FaceID / Huella',
  'language': 'Idioma',
  'select_language': 'Seleccionar idioma',
  'support': 'SOPORTE',
  'help_center': 'Centro de ayuda',
  'report_issue': 'Reportar un problema',
  'about_app': 'Acerca de Attendify',
  'logout': 'Cerrar sesión',
  'logoutConfirm': '¿Estás seguro de que quieres cerrar sesión?',
  'cancel': 'Cancelar',
  'version': 'Versión',

  // Common
  'ok': 'OK',
  'yes': 'Sí',
  'no': 'No',
  'save': 'Guardar',
  'edit': 'Editar',
  'delete': 'Eliminar',
  'back': 'Atrás',
  'next': 'Siguiente',
  'done': 'Hecho',
  'loading': 'Cargando...',
  'error': 'Error',
  'success': 'Éxito',

  // Dashboard
  'dashboard': 'Panel',
  'attendance': 'Asistencia',
  'profile': 'Perfil',
  'schedule': 'Horario',
  'courses': 'Cursos',

  // Authentication
  'login': 'Iniciar sesión',
  'email': 'Correo',
  'password': 'Contraseña',
  'forgot_password': '¿Olvidaste tu contraseña?',
  'dont_have_account': '¿No tienes cuenta?',
  'sign_up': 'Registrarse',
  'already_have_account': '¿Ya tienes cuenta?',
};

// German Translations
const Map<String, String> _deTranslations = {
  // Settings
  'settings': 'Einstellungen',
  'general': 'ALLGEMEIN',
  'notifications': 'Benachrichtigungen',
  'notifications_subtitle': 'Anwesenheitsmeldungen erhalten',
  'biometric_login': 'Biometrische Anmeldung',
  'biometric_subtitle': 'FaceID / Fingerabdruck verwenden',
  'language': 'Sprache',
  'select_language': 'Sprache auswählen',
  'support': 'SUPPORT',
  'help_center': 'Hilfezentrum',
  'report_issue': 'Problem melden',
  'about_app': 'Über Attendify',
  'logout': 'Abmelden',
  'logoutConfirm': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
  'cancel': 'Abbrechen',
  'version': 'Version',

  // Common
  'ok': 'OK',
  'yes': 'Ja',
  'no': 'Nein',
  'save': 'Speichern',
  'edit': 'Bearbeiten',
  'delete': 'Löschen',
  'back': 'Zurück',
  'next': 'Weiter',
  'done': 'Fertig',
  'loading': 'Laden...',
  'error': 'Fehler',
  'success': 'Erfolg',

  // Dashboard
  'dashboard': 'Dashboard',
  'attendance': 'Anwesenheit',
  'profile': 'Profil',
  'schedule': 'Zeitplan',
  'courses': 'Kurse',

  // Authentication
  'login': 'Anmelden',
  'email': 'E-Mail',
  'password': 'Passwort',
  'forgot_password': 'Passwort vergessen?',
  'dont_have_account': 'Kein Konto?',
  'sign_up': 'Registrieren',
  'already_have_account': 'Bereits registriert?',
};

// Delegate for loading localizations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'fr', 'es', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Helper extension for easy access
extension LocalizationExtension on BuildContext {
  AppLocalizations? get loc => AppLocalizations.of(this);
}