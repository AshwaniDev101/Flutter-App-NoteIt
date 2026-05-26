
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../database/shared_preference/shared_preference_manager.dart';



final masterPasswordViewModelProvider = Provider((ref)=>_MasterPasswordViewModel());

class _MasterPasswordViewModel {

  bool updateMasterPassword(String oldPassword, String newPassword)
  {
    final prefs = SharedPreferenceManager.instance;
    final currentPass = prefs.masterPassword;

    if (currentPass != null)
      {
        if (currentPass == oldPassword) {

          prefs.setMasterPassword(newPassword);

          return true;
        }
        return false;
      }
    else
      {
        prefs.setMasterPassword(newPassword);
        return true;
      }
  }
}