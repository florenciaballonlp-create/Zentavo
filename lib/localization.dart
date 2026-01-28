// Localizaciones y preferencias de idioma y moneda
enum AppLanguage { spanish, english, portuguese }

enum AppCurrency {
  usd(symbol: '\$', name: 'USD - Dólar'),
  eur(symbol: '€', name: 'EUR - Euro'),
  gbp(symbol: '£', name: 'GBP - Libra'),
  mxn(symbol: '\$', name: 'MXN - Peso Mexicano'),
  ars(symbol: '\$', name: 'ARS - Peso Argentino'),
  clp(symbol: '\$', name: 'CLP - Peso Chileno'),
  brl(symbol: 'R\$', name: 'BRL - Real Brasileño'),
  inr(symbol: '₹', name: 'INR - Rupia India'),
  jpy(symbol: '¥', name: 'JPY - Yen Japonés'),
  cad(symbol: 'C\$', name: 'CAD - Dólar Canadiense'),
  aud(symbol: 'A\$', name: 'AUD - Dólar Australiano'),
  chf(symbol: 'CHF', name: 'CHF - Franco Suizo'),
  cny(symbol: '¥', name: 'CNY - Yuan Chino'),
  sek(symbol: 'kr', name: 'SEK - Corona Sueca'),
  nok(symbol: 'kr', name: 'NOK - Corona Noruega'),
  zar(symbol: 'R', name: 'ZAR - Rand Sudafricano');

  const AppCurrency({required this.symbol, required this.name});
  final String symbol;
  final String name;

  String formatAmount(double amount) {
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(2)}K';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class AppStrings {
  final AppLanguage language;

  AppStrings({this.language = AppLanguage.spanish});

  // Mensajes generales
  String get appTitle {
    switch (language) {
      case AppLanguage.english:
        return 'Expense Control';
      case AppLanguage.portuguese:
        return 'Controle de Despesas';
      default:
        return 'Control de Gastos';
    }
  }

  String get ingresos {
    switch (language) {
      case AppLanguage.english:
        return 'Income';
      case AppLanguage.portuguese:
        return 'Receitas';
      default:
        return 'Ingresos';
    }
  }

  String get egresos {
    switch (language) {
      case AppLanguage.english:
        return 'Expenses';
      case AppLanguage.portuguese:
        return 'Despesas';
      default:
        return 'Egresos';
    }
  }

  String get balanceTotal {
    switch (language) {
      case AppLanguage.english:
        return 'Total Balance:';
      case AppLanguage.portuguese:
        return 'Saldo Total:';
      default:
        return 'Balance Total:';
    }
  }

  String get verGraficos {
    switch (language) {
      case AppLanguage.english:
        return 'View Charts';
      case AppLanguage.portuguese:
        return 'Ver Gráficos';
      default:
        return 'Ver Gráficos';
    }
  }

  String get reportePDF {
    switch (language) {
      case AppLanguage.english:
        return 'PDF Report';
      case AppLanguage.portuguese:
        return 'Relatório PDF';
      default:
        return 'Reporte PDF';
    }
  }

  String get reporteExcel {
    switch (language) {
      case AppLanguage.english:
        return 'Excel Report';
      case AppLanguage.portuguese:
        return 'Relatório Excel';
      default:
        return 'Reporte Excel';
    }
  }

  String get noMovimientos {
    switch (language) {
      case AppLanguage.english:
        return 'No transactions this month. Use the + button!';
      case AppLanguage.portuguese:
        return 'Sem transações este mês. Use o botão +!';
      default:
        return 'No hay movimientos en este mes. ¡Usa el botón +!';
    }
  }

  String get exportar {
    switch (language) {
      case AppLanguage.english:
        return 'Export';
      case AppLanguage.portuguese:
        return 'Exportar';
      default:
        return 'Exportar';
    }
  }

  String get guardarComo {
    switch (language) {
      case AppLanguage.english:
        return 'Save As';
      case AppLanguage.portuguese:
        return 'Salvar Como';
      default:
        return 'Guardar como';
    }
  }

  String get descargar {
    switch (language) {
      case AppLanguage.english:
        return 'Download';
      case AppLanguage.portuguese:
        return 'Baixar';
      default:
        return 'Descargar';
    }
  }

  String get compartir {
    switch (language) {
      case AppLanguage.english:
        return 'Share';
      case AppLanguage.portuguese:
        return 'Compartilhar';
      default:
        return 'Compartir';
    }
  }

  String get preferencias {
    switch (language) {
      case AppLanguage.english:
        return 'Preferences';
      case AppLanguage.portuguese:
        return 'Preferências';
      default:
        return 'Preferencias';
    }
  }

  String get tema {
    switch (language) {
      case AppLanguage.english:
        return 'Theme';
      case AppLanguage.portuguese:
        return 'Tema';
      default:
        return 'Tema';
    }
  }

  String get idioma {
    switch (language) {
      case AppLanguage.english:
        return 'Language';
      case AppLanguage.portuguese:
        return 'Idioma';
      default:
        return 'Idioma';
    }
  }

  String get moneda {
    switch (language) {
      case AppLanguage.english:
        return 'Currency';
      case AppLanguage.portuguese:
        return 'Moeda';
      default:
        return 'Moneda';
    }
  }

  String get cerrar {
    switch (language) {
      case AppLanguage.english:
        return 'Close';
      case AppLanguage.portuguese:
        return 'Fechar';
      default:
        return 'Cerrar';
    }
  }

  String get titulo {
    switch (language) {
      case AppLanguage.english:
        return 'Title';
      case AppLanguage.portuguese:
        return 'Título';
      default:
        return 'Título';
    }
  }

  String get monto {
    switch (language) {
      case AppLanguage.english:
        return 'Amount';
      case AppLanguage.portuguese:
        return 'Valor';
      default:
        return 'Monto';
    }
  }

  String get categoria {
    switch (language) {
      case AppLanguage.english:
        return 'Category';
      case AppLanguage.portuguese:
        return 'Categoria';
      default:
        return 'Categoría';
    }
  }

  String get justificacion {
    switch (language) {
      case AppLanguage.english:
        return 'Notes';
      case AppLanguage.portuguese:
        return 'Notas';
      default:
        return 'Justificación';
    }
  }

  String get agregarIngreso {
    switch (language) {
      case AppLanguage.english:
        return 'Add Income';
      case AppLanguage.portuguese:
        return 'Adicionar Receita';
      default:
        return 'Agregar Ingreso';
    }
  }

  String get agregarEgreso {
    switch (language) {
      case AppLanguage.english:
        return 'Add Expense';
      case AppLanguage.portuguese:
        return 'Adicionar Despesa';
      default:
        return 'Agregar Egreso';
    }
  }

  String get eliminar {
    switch (language) {
      case AppLanguage.english:
        return 'Delete';
      case AppLanguage.portuguese:
        return 'Excluir';
      default:
        return 'Eliminar';
    }
  }

  String get movimiento {
    switch (language) {
      case AppLanguage.english:
        return 'Transaction';
      case AppLanguage.portuguese:
        return 'Transação';
      default:
        return 'Movimiento';
    }
  }

  String deleteConfirmation(String titulo) {
    switch (language) {
      case AppLanguage.english:
        return 'Are you sure you want to delete "$titulo"?';
      case AppLanguage.portuguese:
        return 'Tem certeza que deseja excluir "$titulo"?';
      default:
        return '¿Estás seguro de que deseas eliminar "$titulo"?';
    }
  }

  String get generandoReporte {
    switch (language) {
      case AppLanguage.english:
        return 'Report generated and shared';
      case AppLanguage.portuguese:
        return 'Relatório gerado e compartilhado';
      default:
        return 'Reporte generado y compartido';
    }
  }

  String get error {
    switch (language) {
      case AppLanguage.english:
        return 'Error';
      case AppLanguage.portuguese:
        return 'Erro';
      default:
        return 'Error';
    }
  }

  String get movimientoEliminado {
    switch (language) {
      case AppLanguage.english:
        return 'Transaction deleted';
      case AppLanguage.portuguese:
        return 'Transação excluída';
      default:
        return 'Movimiento eliminado';
    }
  }

  String get temaDialogoTitle {
    switch (language) {
      case AppLanguage.english:
        return 'Application Theme';
      case AppLanguage.portuguese:
        return 'Tema do Aplicativo';
      default:
        return 'Tema de la aplicación';
    }
  }

  String get sistemaConfig {
    switch (language) {
      case AppLanguage.english:
        return 'Follow system settings';
      case AppLanguage.portuguese:
        return 'Seguir configurações do sistema';
      default:
        return 'Seguir configuración del sistema';
    }
  }

  String get modoClaro {
    switch (language) {
      case AppLanguage.english:
        return 'Light Mode';
      case AppLanguage.portuguese:
        return 'Modo Claro';
      default:
        return 'Modo claro';
    }
  }

  String get modoOscuro {
    switch (language) {
      case AppLanguage.english:
        return 'Dark Mode';
      case AppLanguage.portuguese:
        return 'Modo Escuro';
      default:
        return 'Modo oscuro';
    }
  }

  String get idiomaTitle {
    switch (language) {
      case AppLanguage.english:
        return 'Select Language';
      case AppLanguage.portuguese:
        return 'Seleccionar Idioma';
      default:
        return 'Seleccionar Idioma';
    }
  }

  String get monedaTitle {
    switch (language) {
      case AppLanguage.english:
        return 'Select Currency';
      case AppLanguage.portuguese:
        return 'Seleccionar Moeda';
      default:
        return 'Seleccionar Moneda';
    }
  }
}
