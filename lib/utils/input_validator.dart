class InputValidator {
  // Validate all input fields
  static String? validateNfcInputs({
    required String fbp,
    required String lbp,
    required String aid,
    required String fid,
    required String keyNumber,
    required String key,
  }) {
    if (fbp.trim().isEmpty || lbp.trim().isEmpty) {
      return 'FBP and LBP cannot be empty';
    }

    if (int.tryParse(fbp.trim()) == null || int.tryParse(lbp.trim()) == null) {
      return 'FBP and LBP must be valid numbers';
    }

    if (aid.trim().length != 6) {
      return 'AID must be exactly 6 characters';
    }

    if (key.trim().length != 32) {
      return 'Key must be exactly 32 hex characters';
    }

    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(key.trim())) {
      return 'Key must contain only hex characters (0-9, A-F)';
    }

    return null;
  }
}
