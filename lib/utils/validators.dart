// Input validators for forms
class Validators {
  // Email/Username validator
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome de usuário é obrigatório';
    }
    if (value.length < 3 || value.length > 20) {
      return 'Nome de usuário deve ter entre 3 e 20 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(value)) {
      return 'Nome de usuário deve começar com letra e conter apenas letras, números e underscore';
    }
    return null;
  }

  // Password validator
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra maiúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Senha deve conter pelo menos um número';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Senha deve conter pelo menos um caractere especial';
    }
    return null;
  }

  // Simple password validator (for login)
  static String? validateSimplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira a senha';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  // Password confirmation validator
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != password) {
      return 'Senhas não coincidem';
    }
    return null;
  }

  // Full name validator
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome completo é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(value)) {
      return 'Nome deve conter apenas letras';
    }
    return null;
  }

  // Email validator
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  // Login Input Validator (Email or Username)
  static String? validateLoginInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Usuário ou Email é obrigatório';
    }
    return null;
  }

  // Phone validator (Brazilian format)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final numbers = value.replaceAll(RegExp(r'[^\d]'), '');
    if (numbers.length != 10 && numbers.length != 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  // Title validator
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o título';
    }
    if (value.length < 3) {
      return 'Título deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  // Description validator
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira a descrição';
    }
    if (value.length < 10) {
      return 'Descrição deve ter pelo menos 10 caracteres';
    }
    return null;
  }

  // Category validator
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, selecione uma categoria';
    }
    return null;
  }

  // Format phone number
  static String formatPhone(String phone) {
    final numbers = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    } else if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    }
    return phone;
  }

  // Remove phone formatting
  static String unformatPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}

/// Password strength checker
class PasswordStrength {
  final int score; // 0-5
  final String message;
  final List<String> suggestions;

  PasswordStrength({
    required this.score,
    required this.message,
    required this.suggestions,
  });

  static PasswordStrength check(String password) {
    int score = 0;
    final suggestions = <String>[];

    // Length
    if (password.length >= 8) {
      score++;
    } else {
      suggestions.add('Use pelo menos 8 caracteres');
    }

    // Uppercase
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Adicione letra maiúscula');
    }

    // Lowercase
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Adicione letra minúscula');
    }

    // Number
    if (RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Adicione número');
    }

    // Special character
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Adicione caractere especial');
    }

    String message;
    switch (score) {
      case 0:
      case 1:
        message = 'Muito fraca';
        break;
      case 2:
        message = 'Fraca';
        break;
      case 3:
        message = 'Média';
        break;
      case 4:
        message = 'Forte';
        break;
      case 5:
        message = 'Muito forte';
        break;
      default:
        message = 'Desconhecida';
    }

    return PasswordStrength(
      score: score,
      message: message,
      suggestions: suggestions,
    );
  }
}
