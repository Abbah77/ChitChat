class Validators {
  static String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (validateField(value, 'email') != null || !value.contains('@')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (validateField(value, 'password') != null || value.length < 8) {
      return 'Please enter a password with at least 8 characters';
    }
    return null;
  }
}
