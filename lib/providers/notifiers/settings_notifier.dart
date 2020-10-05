import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsNotifier extends ChangeNotifier {
  static const ACCOUNT_NAME = "accountName";
  static const PRIVATE_KEY = "privateKey";
  static const PASSCODE = "passcode";
  static const PASSCODE_ACTIVE = "passcode_active";
  static const PASSCODE_ACTIVE_DEFAULT = true;
  static const NODE_ENDPOINT = "nodeEndpoint";
  static const PRIVATE_KEY_BACKED_UP = "private_key_backed_up";
  static const BACKUP_LATEST_REMINDER = "backup_latest_reminder";
  static const BACKUP_REMINDER_COUNT = "backup_reminder_count";
  static const IS_MERCHANT_MODE = "is_merchant_mode";

  String _privateKey;
  String _passcode;
  bool _passcodeActive;
  bool _privateKeyBackedUp;
  int _backupLatestReminder;
  int _backupReminderCount;
  bool _isMerchantMode;

  get isInitialized => _preferences != null;
  get accountName => _preferences?.getString(ACCOUNT_NAME);
  get privateKey => _privateKey;
  get passcode => _passcode;
  get passcodeActive => _passcodeActive;
  get nodeEndpoint => _preferences?.getString(NODE_ENDPOINT);
  get privateKeyBackedUp => _privateKeyBackedUp;
  get backupLatestReminder => _backupLatestReminder;
  get backupReminderCount => _backupReminderCount;
  get isMerchantMode => _isMerchantMode;

  set nodeEndpoint(String value) =>
      _preferences?.setString(NODE_ENDPOINT, value);

  set accountName(String value) => _preferences?.setString(ACCOUNT_NAME, value);

  set privateKey(String value) {
    _secureStorage.write(key: PRIVATE_KEY, value: value);
    _privateKey = value;
  }

  set passcode(String value) {
    _secureStorage.write(key: PASSCODE, value: value);
    _passcode = value;
  }

  set passcodeActive(bool value) {
    _secureStorage.write(key: PASSCODE_ACTIVE, value: value.toString());
    _passcodeActive = value;
  }

  set privateKeyBackedUp(bool value) {
    _secureStorage.write(key: PRIVATE_KEY_BACKED_UP, value: value.toString());
    _privateKeyBackedUp = value;
  }

  set backupLatestReminder(int value) {
    _secureStorage.write(key: BACKUP_LATEST_REMINDER, value: value.toString());
    _backupLatestReminder = value;
  }

  set backupReminderCount(int value) {
    _secureStorage.write(key: BACKUP_REMINDER_COUNT, value: value.toString());
    _backupReminderCount = value;
  }

  set isMerchantMode(bool value) {
    _secureStorage.write(key: IS_MERCHANT_MODE, value: value.toString());
    _isMerchantMode = value;
  }

  SharedPreferences _preferences;
  FlutterSecureStorage _secureStorage;

  static SettingsNotifier of(BuildContext context, {bool listen = false}) =>
      Provider.of<SettingsNotifier>(context, listen: listen);

  void init() async {
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = FlutterSecureStorage();
    _secureStorage.readAll().then((values) {
      _privateKey = values[PRIVATE_KEY];
      if (_privateKey == null) {
        _privateKey = _migrateFromPrefs(PRIVATE_KEY);
      }

      _passcode = values[PASSCODE];
      if (_passcode == null) {
        _passcode = _migrateFromPrefs(PASSCODE);
      }

      if (values.containsKey(PASSCODE_ACTIVE)) {
        _passcodeActive = values[PASSCODE_ACTIVE] == "true";
      } else {
        _passcodeActive = PASSCODE_ACTIVE_DEFAULT;
      }

      if (values.containsKey(PRIVATE_KEY_BACKED_UP)) {
        _privateKeyBackedUp = values[PRIVATE_KEY_BACKED_UP] == "true";
      } else {
        _privateKeyBackedUp = false;
      }

      if (values.containsKey(BACKUP_LATEST_REMINDER)) {
        _backupLatestReminder = int.parse(values[BACKUP_LATEST_REMINDER]);
      } else {
        _backupLatestReminder = 0;
      }

      if (values.containsKey(BACKUP_REMINDER_COUNT)) {
        _backupReminderCount = int.parse(values[BACKUP_REMINDER_COUNT]);
      } else {
        _backupReminderCount = 0;
      }

      if (values.containsKey(IS_MERCHANT_MODE)) {
        _isMerchantMode = values[IS_MERCHANT_MODE] == "true";
      } else {
        _isMerchantMode = false;
      }
    }).whenComplete(() => notifyListeners());
  }

  // TODO: @Deprecated("Temporary while people still have the previous app version. Remove after 2020-06-31")
  String _migrateFromPrefs(String key) {
    String value = _preferences.get(key);
    if (value != null) {
      _secureStorage.write(key: key, value: value);
      _preferences?.remove(key);
      debugPrint("Converted $key to secure storage");
    }
    return value;
  }

  void update({String nodeEndpoint}) {
    if (nodeEndpoint != _preferences?.getString(NODE_ENDPOINT)) {
      saveEndpoint(nodeEndpoint);
    }
  }

  void enableMerchantMode() {
    this.isMerchantMode = true;
    notifyListeners();
  }

  void disableMerchantMode() {
    this.isMerchantMode = false;
    notifyListeners();
  }

  void savePasscode(String passcode) {
    this.passcode = passcode;
    notifyListeners();
  }

  void savePasscodeActive(bool value) {
    this.passcodeActive = value;
    if (!passcodeActive) {
      this.passcode = null;
    }
    notifyListeners();
  }

  void saveAccount(String accountName, String privateKey) {
    this.accountName = accountName;
    this.privateKey = privateKey;
    notifyListeners();
  }

  void savePrivateKeyBackedUp(bool value) {
    this.privateKeyBackedUp = value;
    notifyListeners();
  }

  void updateBackupLater() {
    this.backupLatestReminder = DateTime.now().millisecondsSinceEpoch;
    this.backupReminderCount++;
    notifyListeners();
  }

  void removeAccount() {
    _preferences?.remove(ACCOUNT_NAME);
    _secureStorage.delete(key: ACCOUNT_NAME);
    _preferences?.remove(PRIVATE_KEY);
    _secureStorage.delete(key: PRIVATE_KEY);
    _privateKey = null;
    _preferences?.remove(PASSCODE);
    _secureStorage.delete(key: PASSCODE);
    _passcode = null;
    _secureStorage.delete(key: PASSCODE_ACTIVE);
    _passcodeActive = PASSCODE_ACTIVE_DEFAULT;
    _secureStorage.delete(key: PRIVATE_KEY_BACKED_UP);
    _secureStorage.delete(key: BACKUP_LATEST_REMINDER);
    _backupLatestReminder = 0;
    _secureStorage.delete(key: BACKUP_REMINDER_COUNT);
    _backupReminderCount = 0;
    _secureStorage.delete(key: IS_MERCHANT_MODE);
    _isMerchantMode = false;
    notifyListeners();
  }

  void saveEndpoint(String nodeEndpoint) {
    _preferences?.setString(NODE_ENDPOINT, nodeEndpoint);
    notifyListeners();
  }
}
