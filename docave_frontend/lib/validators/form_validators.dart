class FormValidators {
  static String? nombre(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    if (value.trim().length < 2) return 'Mínimo 2 caracteres';
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s'-]+$").hasMatch(value.trim())) {
      return 'Solo letras y espacios';
    }
    return null;
  }

  static String? usuario(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    if (value.trim().length < 3) return 'Mínimo 3 caracteres';
    if (value.trim().length > 20) return 'Máximo 20 caracteres';
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(value.trim())) {
      return 'Solo letras, números, _ . -';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  static String? telefono(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (!RegExp(r'^\d+$').hasMatch(digits)) return 'Solo números';
    if (digits.length < 7 || digits.length > 15) return 'Entre 7 y 15 dígitos';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Necesita una mayúscula';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Necesita un número';
    if (!RegExp(r'[!@#\$&*~%^()\-_=+\[\]{};:,.<>?/|]').hasMatch(value)) {
      return 'Necesita un carácter especial';
    }
    return null;
  }

  static String? Function(String?) confirmarPassword(String passwordValue) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Campo obligatorio';
      if (value != passwordValue) return 'Las contraseñas no coinciden';
      return null;
    };
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }
}
