// Localizaciones y preferencias de idioma y moneda
enum AppLanguage { spanish, english, portuguese, italian }

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
        return 'Zentavo';
      case AppLanguage.portuguese:
        return 'Zentavo';
      case AppLanguage.italian:
        return 'Zentavo';
      default:
        return 'Zentavo';
    }
  }

  String get ingresos {
    switch (language) {
      case AppLanguage.english:
        return 'Income';
      case AppLanguage.portuguese:
        return 'Receitas';
      case AppLanguage.italian:
        return 'Entrate';
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
      case AppLanguage.italian:
        return 'Spese';
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
      case AppLanguage.italian:
        return 'Saldo Totale:';
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
      case AppLanguage.italian:
        return 'Visualizza Grafici';
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
      case AppLanguage.italian:
        return 'Relazione PDF';
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
      case AppLanguage.italian:
        return 'Relazione Excel';
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
      case AppLanguage.italian:
        return 'Nessuna transazione questo mese. Usa il pulsante +!';
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
      case AppLanguage.italian:
        return 'Esporta';
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
      case AppLanguage.italian:
        return 'Salva con nome';
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
      case AppLanguage.italian:
        return 'Scarica';
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
      case AppLanguage.italian:
        return 'Condividi';
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
      case AppLanguage.italian:
        return 'Preferenze';
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
      case AppLanguage.italian:
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
      case AppLanguage.italian:
        return 'Lingua';
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
      case AppLanguage.italian:
        return 'Valuta';
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
      case AppLanguage.italian:
        return 'Chiudi';
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
      case AppLanguage.italian:
        return 'Titolo';
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
      case AppLanguage.italian:
        return 'Importo';
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
      case AppLanguage.italian:
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
      case AppLanguage.italian:
        return 'Note';
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
      case AppLanguage.italian:
        return 'Aggiungi Entrata';
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
      case AppLanguage.italian:
        return 'Aggiungi Spesa';
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
      case AppLanguage.italian:
        return 'Elimina';
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
      case AppLanguage.italian:
        return 'Transazione';
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
      case AppLanguage.italian:
        return 'Sei sicuro di voler eliminare "$titulo"?';
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
      case AppLanguage.italian:
        return 'Rapporto generato e condiviso';
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
      case AppLanguage.italian:
        return 'Errore';
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
      case AppLanguage.italian:
        return 'Transazione eliminata';
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
      case AppLanguage.italian:
        return 'Tema dell\'Applicazione';
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
      case AppLanguage.italian:
        return 'Segui le impostazioni di sistema';
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
      case AppLanguage.italian:
        return 'Modalità Chiara';
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
      case AppLanguage.italian:
        return 'Modalità Scura';
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
      case AppLanguage.italian:
        return 'Seleziona Lingua';
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
      case AppLanguage.italian:
        return 'Seleziona Valuta';
      default:
        return 'Seleccionar Moneda';
    }
  }

  String get presupuesto {
    switch (language) {
      case AppLanguage.english:
        return 'Budget';
      case AppLanguage.portuguese:
        return 'Orçamento';
      case AppLanguage.italian:
        return 'Budget';
      default:
        return 'Presupuesto';
    }
  }

  String get presupuestoMensual {
    switch (language) {
      case AppLanguage.english:
        return 'Monthly Budget';
      case AppLanguage.portuguese:
        return 'Orçamento Mensal';
      case AppLanguage.italian:
        return 'Budget Mensile';
      default:
        return 'Presupuesto Mensual';
    }
  }

  String get gastado {
    switch (language) {
      case AppLanguage.english:
        return 'Spent';
      case AppLanguage.portuguese:
        return 'Gasto';
      case AppLanguage.italian:
        return 'Speso';
      default:
        return 'Gastado';
    }
  }

  String get definirPresupuesto {
    switch (language) {
      case AppLanguage.english:
        return 'Set Monthly Budget';
      case AppLanguage.portuguese:
        return 'Definir Orçamento Mensal';
      case AppLanguage.italian:
        return 'Imposta Budget Mensile';
      default:
        return 'Definir Presupuesto Mensual';
    }
  }

  String get presupuestoExcedido {
    switch (language) {
      case AppLanguage.english:
        return 'Budget Exceeded!';
      case AppLanguage.portuguese:
        return 'Orçamento Excedido!';
      case AppLanguage.italian:
        return 'Budget Superato!';
      default:
        return '¡Presupuesto Excedido!';
    }
  }

  String presupuestoExcedidoMsg(String excedente) {
    switch (language) {
      case AppLanguage.english:
        return 'You have exceeded your budget by $excedente';
      case AppLanguage.portuguese:
        return 'Você excedeu seu orçamento em $excedente';
      case AppLanguage.italian:
        return 'Hai superato il tuo budget di $excedente';
      default:
        return 'Has excedido tu presupuesto en $excedente';
    }
  }

  String get presupuestoOk {
    switch (language) {
      case AppLanguage.english:
        return 'OK';
      case AppLanguage.portuguese:
        return 'OK';
      case AppLanguage.italian:
        return 'OK';
      default:
        return 'OK';
    }
  }

  String get montoPresupuesto {
    switch (language) {
      case AppLanguage.english:
        return 'Budget Amount';
      case AppLanguage.portuguese:
        return 'Valor do Orçamento';
      case AppLanguage.italian:
        return 'Importo del Budget';
      default:
        return 'Cantidad del Presupuesto';
    }
  }

  String get presupuestoPendiente {
    switch (language) {
      case AppLanguage.english:
        return 'Remaining: ';
      case AppLanguage.portuguese:
        return 'Restante: ';
      case AppLanguage.italian:
        return 'Disponibile: ';
      default:
        return 'Disponible: ';
    }
  }

  String get configuracion {
    switch (language) {
      case AppLanguage.english:
        return 'Settings';
      case AppLanguage.portuguese:
        return 'Configurações';
      case AppLanguage.italian:
        return 'Impostazioni';
      default:
        return 'Configuración';
    }
  }

  String get temaDialogo {
    switch (language) {
      case AppLanguage.english:
        return 'Application Theme';
      case AppLanguage.portuguese:
        return 'Tema do Aplicativo';
      case AppLanguage.italian:
        return 'Tema dell\'Applicazione';
      default:
        return 'Tema de la aplicación';
    }
  }

  String get seguirSistema {
    switch (language) {
      case AppLanguage.english:
        return 'Follow system settings';
      case AppLanguage.portuguese:
        return 'Seguir configurações do sistema';
      case AppLanguage.italian:
        return 'Segui le impostazioni di sistema';
      default:
        return 'Seguir configuración del sistema';
    }
  }

  String get cancelar {
    switch (language) {
      case AppLanguage.english:
        return 'Cancel';
      case AppLanguage.portuguese:
        return 'Cancelar';
      case AppLanguage.italian:
        return 'Annulla';
      default:
        return 'Cancelar';
    }
  }

  String get guardar {
    switch (language) {
      case AppLanguage.english:
        return 'Save';
      case AppLanguage.portuguese:
        return 'Salvar';
      case AppLanguage.italian:
        return 'Salva';
      default:
        return 'Guardar';
    }
  }

  String get copiar {
    switch (language) {
      case AppLanguage.english:
        return 'Copy';
      case AppLanguage.portuguese:
        return 'Copiar';
      case AppLanguage.italian:
        return 'Copia';
      default:
        return 'Copiar';
    }
  }

  String get descargarComo {
    switch (language) {
      case AppLanguage.english:
        return 'Download as:';
      case AppLanguage.portuguese:
        return 'Baixar como:';
      case AppLanguage.italian:
        return 'Scarica come:';
      default:
        return 'Descargar como:';
    }
  }

  String get json {
    switch (language) {
      case AppLanguage.english:
        return 'JSON';
      case AppLanguage.portuguese:
        return 'JSON';
      case AppLanguage.italian:
        return 'JSON';
      default:
        return 'JSON';
    }
  }

  String get csv {
    switch (language) {
      case AppLanguage.english:
        return 'CSV';
      case AppLanguage.portuguese:
        return 'CSV';
      case AppLanguage.italian:
        return 'CSV';
      default:
        return 'CSV';
    }
  }

  String get txt {
    switch (language) {
      case AppLanguage.english:
        return 'TXT';
      case AppLanguage.portuguese:
        return 'TXT';
      case AppLanguage.italian:
        return 'TXT';
      default:
        return 'TXT';
    }
  }

  String get pdf {
    switch (language) {
      case AppLanguage.english:
        return 'PDF';
      case AppLanguage.portuguese:
        return 'PDF';
      case AppLanguage.italian:
        return 'PDF';
      default:
        return 'PDF';
    }
  }

  String get excel {
    switch (language) {
      case AppLanguage.english:
        return 'Excel';
      case AppLanguage.portuguese:
        return 'Excel';
      case AppLanguage.italian:
        return 'Excel';
      default:
        return 'Excel';
    }
  }

  String get reportePDFMensual {
    switch (language) {
      case AppLanguage.english:
        return 'Monthly PDF Report';
      case AppLanguage.portuguese:
        return 'Relatório PDF Mensal';
      case AppLanguage.italian:
        return 'Relazione PDF Mensile';
      default:
        return 'Reporte PDF Mensual';
    }
  }

  String get reporteExcelMensual {
    switch (language) {
      case AppLanguage.english:
        return 'Monthly Excel Report';
      case AppLanguage.portuguese:
        return 'Relatório Excel Mensal';
      case AppLanguage.italian:
        return 'Relazione Excel Mensile';
      default:
        return 'Reporte Excel Mensual';
    }
  }

  String get compartirPDFMediante {
    switch (language) {
      case AppLanguage.english:
        return 'Share PDF via:';
      case AppLanguage.portuguese:
        return 'Compartilhar PDF via:';
      case AppLanguage.italian:
        return 'Condividi PDF tramite:';
      default:
        return 'Compartir PDF mediante:';
    }
  }

  String get whatsapp {
    switch (language) {
      case AppLanguage.english:
        return 'WhatsApp';
      case AppLanguage.portuguese:
        return 'WhatsApp';
      case AppLanguage.italian:
        return 'WhatsApp';
      default:
        return 'WhatsApp';
    }
  }

  String get email {
    switch (language) {
      case AppLanguage.english:
        return 'Email';
      case AppLanguage.portuguese:
        return 'Email';
      case AppLanguage.italian:
        return 'Email';
      default:
        return 'Email';
    }
  }

  String get telegram {
    switch (language) {
      case AppLanguage.english:
        return 'Telegram';
      case AppLanguage.portuguese:
        return 'Telegram';
      case AppLanguage.italian:
        return 'Telegram';
      default:
        return 'Telegram';
    }
  }
}
