// Localizaciones y preferencias de idioma y moneda
enum AppLanguage { spanish, english, portuguese, italian, chinese, japanese }

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
      case AppLanguage.chinese:
        return 'Zentavo';
      case AppLanguage.japanese:
        return 'Zentavo';
      default:
        return 'Zentavo';
    }
  }

  String get tuControlFinanciero {
    switch (language) {
      case AppLanguage.english:
        return 'Your financial control';
      case AppLanguage.portuguese:
        return 'Seu controle financeiro';
      case AppLanguage.italian:
        return 'Il tuo controllo finanziario';
      case AppLanguage.chinese:
        return '您的财务控制';
      case AppLanguage.japanese:
        return 'あなたの財務管理';
      default:
        return 'Tu control financiero';
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
      case AppLanguage.chinese:
        return '收入';
      case AppLanguage.japanese:
        return '収入';
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
      case AppLanguage.chinese:
        return '支出';
      case AppLanguage.japanese:
        return '支出';
      default:
        return 'Egresos';
    }
  }

  String get transacciones {
    switch (language) {
      case AppLanguage.english:
        return 'Transactions';
      case AppLanguage.portuguese:
        return 'Transações';
      case AppLanguage.italian:
        return 'Transazioni';
      case AppLanguage.chinese:
        return '交易';
      case AppLanguage.japanese:
        return '取引';
      default:
        return 'Transacciones';
    }
  }

  String get ahorros {
    switch (language) {
      case AppLanguage.english:
        return 'Savings';
      case AppLanguage.portuguese:
        return 'Poupança';
      case AppLanguage.italian:
        return 'Risparmi';
      case AppLanguage.chinese:
        return '储蓄';
      case AppLanguage.japanese:
        return '貯蓄';
      default:
        return 'Ahorros';
    }
  }

  String get eventosCompartidos {
    switch (language) {
      case AppLanguage.english:
        return 'Shared Events';
      case AppLanguage.portuguese:
        return 'Eventos Compartilhados';
      case AppLanguage.italian:
        return 'Eventi Condivisi';
      case AppLanguage.chinese:
        return '共享活动';
      case AppLanguage.japanese:
        return '共有イベント';
      default:
        return 'Eventos Compartidos';
    }
  }

  String get gastosFijos {
    switch (language) {
      case AppLanguage.english:
        return 'Fixed Expenses';
      case AppLanguage.portuguese:
        return 'Despesas Fixas';
      case AppLanguage.italian:
        return 'Spese Fisse';
      case AppLanguage.chinese:
        return '固定支出';
      case AppLanguage.japanese:
        return '固定支出';
      default:
        return 'Gastos Fijos';
    }
  }

  String get misCategorias {
    switch (language) {
      case AppLanguage.english:
        return 'My Categories';
      case AppLanguage.portuguese:
        return 'Minhas Categorias';
      case AppLanguage.italian:
        return 'Le Mie Categorie';
      case AppLanguage.chinese:
        return '我的类别';
      case AppLanguage.japanese:
        return '私のカテゴリ';
      default:
        return 'Mis Categorías';
    }
  }

  String get monedasMultiples {
    switch (language) {
      case AppLanguage.english:
        return 'Multiple Currencies';
      case AppLanguage.portuguese:
        return 'Múltiplas Moedas';
      case AppLanguage.italian:
        return 'Valute Multiple';
      case AppLanguage.chinese:
        return '多种货币';
      case AppLanguage.japanese:
        return '複数通貨';
      default:
        return 'Monedas Múltiples';
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
      case AppLanguage.chinese:
        return '总余额:';
      case AppLanguage.japanese:
        return '合計残高:';
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
      case AppLanguage.chinese:
        return '查看图表';
      case AppLanguage.japanese:
        return 'チャートを表示';
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
      case AppLanguage.chinese:
        return 'PDF报告';
      case AppLanguage.japanese:
        return 'PDFレポート';
      default:
        return 'Informe PDF';
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
      case AppLanguage.chinese:
        return 'Excel报告';
      case AppLanguage.japanese:
        return 'Excelレポート';
      default:
        return 'Informe Excel';
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
      case AppLanguage.chinese:
        return '本月没有交易。使用 + 按钮！';
      case AppLanguage.japanese:
        return '今月の取引はありません。+ボタンを使用してください！';
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
      case AppLanguage.chinese:
        return '导出';
      case AppLanguage.japanese:
        return 'エクスポート';
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
      case AppLanguage.chinese:
        return '另存为';
      case AppLanguage.japanese:
        return '名前を付けて保存';
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
      case AppLanguage.chinese:
        return '下载';
      case AppLanguage.japanese:
        return 'ダウンロード';
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
      case AppLanguage.chinese:
        return '分享';
      case AppLanguage.japanese:
        return '共有';
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
      case AppLanguage.chinese:
        return '偏好';
      case AppLanguage.japanese:
        return '設定';
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
      case AppLanguage.chinese:
        return '主题';
      case AppLanguage.japanese:
        return 'テーマ';
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
      case AppLanguage.chinese:
        return '语言';
      case AppLanguage.japanese:
        return '言語';
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
      case AppLanguage.chinese:
        return '货币';
      case AppLanguage.japanese:
        return '通貨';
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
      case AppLanguage.chinese:
        return '关闭';
      case AppLanguage.japanese:
        return '閉じる';
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
      case AppLanguage.chinese:
        return '标题';
      case AppLanguage.japanese:
        return 'タイトル';
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
      case AppLanguage.chinese:
        return '金额';
      case AppLanguage.japanese:
        return '金額';
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
      case AppLanguage.chinese:
        return '类别';
      case AppLanguage.japanese:
        return 'カテゴリ';
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
      case AppLanguage.chinese:
        return '备注';
      case AppLanguage.japanese:
        return 'メモ';
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
      case AppLanguage.chinese:
        return '添加收入';
      case AppLanguage.japanese:
        return '収入を追加';
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
      case AppLanguage.chinese:
        return '添加支出';
      case AppLanguage.japanese:
        return '支出を追加';
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
      case AppLanguage.chinese:
        return '删除';
      case AppLanguage.japanese:
        return '削除';
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
      case AppLanguage.chinese:
        return '交易';
      case AppLanguage.japanese:
        return 'トランザクション';
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
      case AppLanguage.chinese:
        return '您确定要删除 "$titulo" 吗？';
      case AppLanguage.japanese:
        return '"$titulo" を削除してもよろしいですか？';
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
      case AppLanguage.chinese:
        return '报告已生成并共享';
      case AppLanguage.japanese:
        return 'レポートが生成され共有されました';
      default:
        return 'Informe generado y compartido';
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
      case AppLanguage.chinese:
        return '错误';
      case AppLanguage.japanese:
        return 'エラー';
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
      case AppLanguage.chinese:
        return '交易已删除';
      case AppLanguage.japanese:
        return '取引が削除されました';
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
      case AppLanguage.chinese:
        return '应用程序主题';
      case AppLanguage.japanese:
        return 'アプリケーションテーマ';
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
      case AppLanguage.chinese:
        return '跟随系统设置';
      case AppLanguage.japanese:
        return 'システム設定に従う';
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
      case AppLanguage.chinese:
        return '浅色模式';
      case AppLanguage.japanese:
        return 'ライトモード';
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
      case AppLanguage.chinese:
        return '深色模式';
      case AppLanguage.japanese:
        return 'ダークモード';
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
      case AppLanguage.chinese:
        return '选择语言';
      case AppLanguage.japanese:
        return '言語を選択';
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
      case AppLanguage.chinese:
        return '选择货币';
      case AppLanguage.japanese:
        return '通貨を選択';
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
      case AppLanguage.chinese:
        return '预算';
      case AppLanguage.japanese:
        return '予算';
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
      case AppLanguage.chinese:
        return '月度预算';
      case AppLanguage.japanese:
        return '月間予算';
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
      case AppLanguage.chinese:
        return '已支出';
      case AppLanguage.japanese:
        return '支出済み';
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
      case AppLanguage.chinese:
        return '设置月度预算';
      case AppLanguage.japanese:
        return '月間予算を設定';
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
      case AppLanguage.chinese:
        return '超出预算！';
      case AppLanguage.japanese:
        return '予算を超過しました！';
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
      case AppLanguage.chinese:
        return '您已超出预算 $excedente';
      case AppLanguage.japanese:
        return '予算を $excedente だけ超過しました';
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
      case AppLanguage.chinese:
        return '确定';
      case AppLanguage.japanese:
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
      case AppLanguage.chinese:
        return '预算金额';
      case AppLanguage.japanese:
        return '予算金額';
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
      case AppLanguage.chinese:
        return '剩余: ';
      case AppLanguage.japanese:
        return '残り: ';
      default:
        return 'Disponible: ';
    }
  }

  String get miPerfil {
    switch (language) {
      case AppLanguage.english:
        return 'My Profile';
      case AppLanguage.portuguese:
        return 'Meu Perfil';
      case AppLanguage.italian:
        return 'Il Mio Profilo';
      case AppLanguage.chinese:
        return '我的资料';
      case AppLanguage.japanese:
        return 'マイプロフィール';
      default:
        return 'Mi Perfil';
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
      case AppLanguage.chinese:
        return '设置';
      case AppLanguage.japanese:
        return '設定';
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
      case AppLanguage.chinese:
        return '应用程序主题';
      case AppLanguage.japanese:
        return 'アプリケーションテーマ';
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
      case AppLanguage.chinese:
        return '跟随系统设置';
      case AppLanguage.japanese:
        return 'システム設定に従う';
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
      case AppLanguage.chinese:
        return '取消';
      case AppLanguage.japanese:
        return 'キャンセル';
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
      case AppLanguage.chinese:
        return '保存';
      case AppLanguage.japanese:
        return '保存';
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
      case AppLanguage.chinese:
        return '复制';
      case AppLanguage.japanese:
        return 'コピー';
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
      case AppLanguage.chinese:
        return '下载为:';
      case AppLanguage.japanese:
        return 'ダウンロード形式:';
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
      case AppLanguage.chinese:
        return 'JSON';
      case AppLanguage.japanese:
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
      case AppLanguage.chinese:
        return 'CSV';
      case AppLanguage.japanese:
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
      case AppLanguage.chinese:
        return 'TXT';
      case AppLanguage.japanese:
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
      case AppLanguage.chinese:
        return 'PDF';
      case AppLanguage.japanese:
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
      case AppLanguage.chinese:
        return 'Excel';
      case AppLanguage.japanese:
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
      case AppLanguage.chinese:
        return '月度PDF报告';
      case AppLanguage.japanese:
        return '月間PDFレポート';
      default:
        return 'Informe PDF Mensual';
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
      case AppLanguage.chinese:
        return '月度Excel报告';
      case AppLanguage.japanese:
        return '月間Excelレポート';
      default:
        return 'Informe Excel Mensual';
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
      case AppLanguage.chinese:
        return '通过以下方式分享PDF:';
      case AppLanguage.japanese:
        return 'PDFを共有:';
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
      case AppLanguage.chinese:
        return 'WhatsApp';
      case AppLanguage.japanese:
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
      case AppLanguage.chinese:
        return '电子邮件';
      case AppLanguage.japanese:
        return 'メール';
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
      case AppLanguage.chinese:
        return 'Telegram';
      case AppLanguage.japanese:
        return 'Telegram';
      default:
        return 'Telegram';
    }
  }

  String get reportes {
    switch (language) {
      case AppLanguage.english:
        return 'Reports';
      case AppLanguage.portuguese:
        return 'Relatórios';
      case AppLanguage.italian:
        return 'Rapporti';
      case AppLanguage.chinese:
        return '报告';
      case AppLanguage.japanese:
        return 'レポート';
      default:
        return 'Informes';
    }
  }

  String get manualDeUso {
    switch (language) {
      case AppLanguage.english:
        return 'User Manual';
      case AppLanguage.portuguese:
        return 'Manual de Uso';
      case AppLanguage.italian:
        return 'Manuale Utente';
      case AppLanguage.chinese:
        return '用户手册';
      case AppLanguage.japanese:
        return 'ユーザーマニュアル';
      default:
        return 'Manual de uso';
    }
  }

  String get compartirApp {
    switch (language) {
      case AppLanguage.english:
        return 'Share App';
      case AppLanguage.portuguese:
        return 'Compartilhar App';
      case AppLanguage.italian:
        return 'Condividi App';
      case AppLanguage.chinese:
        return '分享应用';
      case AppLanguage.japanese:
        return 'アプリを共有';
      default:
        return 'Compartir App';
    }
  }

  // Manual de uso - Inicio
  String get manualBienvenida {
    switch (language) {
      case AppLanguage.english:
        return 'Welcome to Zentavo. Here\'s a quick guide to using the app:';
      case AppLanguage.portuguese:
        return 'Bem-vindo ao Zentavo. Aqui está um guia rápido para usar o aplicativo:';
      case AppLanguage.italian:
        return 'Benvenuto in Zentavo. Ecco una guida rapida per utilizzare l\'app:';
      case AppLanguage.chinese:
        return '欢迎来到 Zentavo。以下是一个使用应用程序的快速指南:';
      case AppLanguage.japanese:
        return 'Zentavoへようこそ。これはアプリを使用するためのクイックガイドです:';
      default:
        return 'Bienvenido a Zentavo. Aquí tienes una guía rápida para usar la app:';
    }
  }

  String get manualTransaccionesTitulo {
    switch (language) {
      case AppLanguage.english:
        return '1) Transactions';
      case AppLanguage.portuguese:
        return '1) Transações';
      case AppLanguage.italian:
        return '1) Transazioni';
      case AppLanguage.chinese:
        return '1) 交易';
      case AppLanguage.japanese:
        return '1) 取引';
      default:
        return '1) Transacciones';
    }
  }

  String get manualTransaccionesP1 {
    switch (language) {
      case AppLanguage.english:
        return '• Add income or expenses with the buttons at the bottom.';
      case AppLanguage.portuguese:
        return '• Adicione receitas ou despesas com os botões na parte inferior.';
      case AppLanguage.italian:
        return '• Aggiungi entrate o spese con i pulsanti in basso.';
      case AppLanguage.chinese:
        return '• 使用下边的按钮添加收入或支出。';
      case AppLanguage.japanese:
        return '• 下迊のボタンを使用して収入または支出を追加してください。';
      default:
        return '• Agrega ingresos o egresos con los botones de la parte inferior.';
    }
  }

  String get manualTransaccionesP2 {
    switch (language) {
      case AppLanguage.english:
        return '• You can edit by tapping a transaction or delete it with the trash icon.';
      case AppLanguage.portuguese:
        return '• Você pode editar tocando em uma transação ou excluí-la com o ícone de lixeira.';
      case AppLanguage.italian:
        return '• Puoi modificare toccando una transazione o eliminarla con l\'icona del cestino.';
      case AppLanguage.chinese:
        return '• 您可以通过点击一次交易来编辑或使用庞箱图标削除它。';
      case AppLanguage.japanese:
        return '• 取引をタップして编集したり、ゴミ箱アイコンで削除したりできます。';
      default:
        return '• Puedes editar tocando un movimiento o eliminarlo con el ícono de basura.';
    }
  }

  String get manualTransaccionesP3 {
    switch (language) {
      case AppLanguage.english:
        return '• Use the month selector to review history.';
      case AppLanguage.portuguese:
        return '• Use o seletor de mês para revisar o histórico.';
      case AppLanguage.italian:
        return '• Usa il selettore del mese per rivedere la cronologia.';
      case AppLanguage.chinese:
        return '• 使用月份选择器查看历史记录。';
      case AppLanguage.japanese:
        return '• 月一度選択子を使用して履歴を確認してください。';
      default:
        return '• Usa el selector de mes para revisar históricos.';
    }
  }

  String get manualAhorrosTitulo {
    switch (language) {
      case AppLanguage.english:
        return '2) Savings';
      case AppLanguage.portuguese:
        return '2) Poupança';
      case AppLanguage.italian:
        return '2) Risparmi';
      case AppLanguage.chinese:
        return '2) 储蓄';
      case AppLanguage.japanese:
        return '2) 貯蓄';
      default:
        return '2) Ahorros';
    }
  }

  String get manualAhorrosP1 {
    switch (language) {
      case AppLanguage.english:
        return '• Savings are automatically calculated monthly (income - expenses).';
      case AppLanguage.portuguese:
        return '• A poupança é calculada automaticamente mensalmente (receitas - despesas).';
      case AppLanguage.italian:
        return '• I risparmi sono calcolati automaticamente mensilmente (entrate - spese).';
      case AppLanguage.chinese:
        return '• 储蓄按月自动计算（收入 - 支出）。';
      case AppLanguage.japanese:
        return '• 貯蓄は月間で自動的に計算されます（収入 - 支出）。';
      default:
        return '• Los ahorros se calculan automáticamente por mes (ingresos - egresos).';
    }
  }

  String get manualAhorrosP2 {
    switch (language) {
      case AppLanguage.english:
        return '• You can make a withdrawal from the "Money Withdrawal" button.';
      case AppLanguage.portuguese:
        return '• Você pode fazer um saque pelo botão "Retirada de dinheiro".';
      case AppLanguage.italian:
        return '• Puoi effettuare un prelievo dal pulsante "Prelievo di denaro".';
      case AppLanguage.chinese:
        return '• 您可以从“提取上下文”按钮进行提取。';
      case AppLanguage.japanese:
        return '• 「貯金を引き出す」ボタンから引き出しをできます。';
      default:
        return '• Puedes realizar una extracción desde el botón "Extracción de dinero".';
    }
  }

  String get manualGastosFijosTitulo {
    switch (language) {
      case AppLanguage.english:
        return '3) Fixed Expenses';
      case AppLanguage.portuguese:
        return '3) Despesas Fixas';
      case AppLanguage.italian:
        return '3) Spese Fisse';
      case AppLanguage.chinese:
        return '3) 固定支出';
      case AppLanguage.japanese:
        return '3) 固定支出';
      default:
        return '3) Gastos fijos';
    }
  }

  String get manualGastosFijosP1 {
    switch (language) {
      case AppLanguage.english:
        return '• When creating an expense, you can mark it as fixed with the checkbox.';
      case AppLanguage.portuguese:
        return '• Ao criar uma despesa, você pode marcá-la como fixa com a caixa de seleção.';
      case AppLanguage.italian:
        return '• Quando crei una spesa, puoi contrassegnarla come fissa con la casella di controllo.';
      case AppLanguage.chinese:
        return '• 创建支出时，你可以使用复选框汽化为固定。';
      case AppLanguage.japanese:
        return '• 支出を作成する時、チェックボックスで固定としてマークできます。';
      default:
        return '• Al crear un egreso, puedes marcarlo como gasto fijo con el tilde.';
    }
  }

  String get manualGastosFijosP2 {
    switch (language) {
      case AppLanguage.english:
        return '• You can also manage them from Settings > Fixed Expenses.';
      case AppLanguage.portuguese:
        return '• Você também pode gerenciá-las em Configurações > Despesas Fixas.';
      case AppLanguage.italian:
        return '• Puoi anche gestirle da Impostazioni > Spese Fisse.';
      default:
        return '• También puedes gestionarlos desde Configuración > Gastos Fijos.';
    }
  }

  String get manualGastosFijosP3 {
    switch (language) {
      case AppLanguage.english:
        return '• Each fixed expense has an edit button (pencil) and a delete button.';
      case AppLanguage.portuguese:
        return '• Cada despesa fixa tem um botão de editar (lápis) e um botão de excluir.';
      case AppLanguage.italian:
        return '• Ogni spesa fissa ha un pulsante di modifica (matita) e un pulsante di eliminazione.';
      case AppLanguage.chinese:
        return '• 每个固定支出都有一个编辑按钮（铅笔）和一个删除按钮。';
      case AppLanguage.japanese:
        return '• 各固定支出には编集ボタン（铅笔）と削除ボタンがあります。';
      default:
        return '• Cada gasto fijo tiene un botón de editar (lápiz) y un botón de eliminar.';
    }
  }

  String get manualPresupuestoTitulo {
    switch (language) {
      case AppLanguage.english:
        return '4) Monthly Budget';
      case AppLanguage.portuguese:
        return '4) Orçamento Mensal';
      case AppLanguage.italian:
        return '4) Budget Mensile';
      case AppLanguage.chinese:
        return '4) 月度预算';
      case AppLanguage.japanese:
        return '4) 月間予算';
      default:
        return '4) Presupuesto mensual';
    }
  }

  String get manualPresupuestoP1 {
    switch (language) {
      case AppLanguage.english:
        return '• Set a budget and the app will notify you if you exceed it.';
      case AppLanguage.portuguese:
        return '• Defina um orçamento e o aplicativo notificará você se excedê-lo.';
      case AppLanguage.italian:
        return '• Imposta un budget e l\'app ti avviserà se lo superi.';
      default:
        return '• Define un presupuesto y la app te avisa si lo superas.';
    }
  }

  String get manualReportesTitulo {
    switch (language) {
      case AppLanguage.english:
        return '5) Reports and Downloads';
      case AppLanguage.portuguese:
        return '5) Relatórios e Downloads';
      case AppLanguage.italian:
        return '5) Rapporti e Download';
      case AppLanguage.chinese:
        return '5) 报告和下载';
      case AppLanguage.japanese:
        return '5) レポートとダウンロード';
      default:
        return '5) Informes y descargas';
    }
  }

  String get manualReportesP1 {
    switch (language) {
      case AppLanguage.english:
        return '• Generate reports in PDF or Excel from the options menu.';
      case AppLanguage.portuguese:
        return '• Gere relatórios em PDF ou Excel no menu de opções.';
      case AppLanguage.italian:
        return '• Genera rapporti in PDF o Excel dal menu opzioni.';
      case AppLanguage.chinese:
        return '• 从选项菜单中生成PDF或Excel报告。';
      case AppLanguage.japanese:
        return '• オプションメニューかPDFまたはExcelレポートを生成します。';
      default:
        return '• Genera informes en PDF o Excel desde el menú de opciones.';
    }
  }

  String get manualReportesP2 {
    switch (language) {
      case AppLanguage.english:
        return '• You can export JSON, CSV or TXT from "Download".';
      case AppLanguage.portuguese:
        return '• Você pode exportar JSON, CSV ou TXT em "Baixar".';
      case AppLanguage.italian:
        return '• Puoi esportare JSON, CSV o TXT da "Scarica".';
      case AppLanguage.chinese:
        return '• 你可以从“下载”中导出JSON、CSV或TXT。';
      case AppLanguage.japanese:
        return '• 「ダウンロード」かJSON、CSVまTXTをエクスポートできます。';
      default:
        return '• Puedes exportar JSON, CSV o TXT desde "Descargar".';
    }
  }

  String get manualSeguridadTitulo {
    switch (language) {
      case AppLanguage.english:
        return '6) Security';
      case AppLanguage.portuguese:
        return '6) Segurança';
      case AppLanguage.italian:
        return '6) Sicurezza';
      case AppLanguage.chinese:
        return '6) 安全';
      case AppLanguage.japanese:
        return '6) セキュリティ';
      default:
        return '6) Seguridad';
    }
  }

  String get manualSeguridadP1 {
    switch (language) {
      case AppLanguage.english:
        return '• The app requests biometric or device PIN when starting.';
      case AppLanguage.portuguese:
        return '• O aplicativo solicita biometria ou código do dispositivo ao iniciar.';
      case AppLanguage.italian:
        return '• L\'app richiede biometria o codice del dispositivo all\'avvio.';
      case AppLanguage.chinese:
        return '• 应用程序在启动时请求生物指纹或设备PIN。';
      case AppLanguage.japanese:
        return '• アプリを起動する時、誋訬残を会とうやデバイスPINを設定してください。';
      default:
        return '• La app solicita biometría o código del dispositivo al iniciar.';
    }
  }

  String get manualEventosTitulo {
    switch (language) {
      case AppLanguage.english:
        return '7) Shared Events';
      case AppLanguage.portuguese:
        return '7) Eventos Compartilhados';
      case AppLanguage.italian:
        return '7) Eventi Condivisi';
      case AppLanguage.chinese:
        return '7) 共享事件';
      case AppLanguage.japanese:
        return '7) 共有イベント';
      default:
        return '7) Eventos compartidos';
    }
  }

  String get manualEventosP1 {
    switch (language) {
      case AppLanguage.english:
        return '• Create events for trips or gatherings with a budget and track shared expenses.';
      case AppLanguage.portuguese:
        return '• Crie eventos para viagens ou encontros com orçamento e controle despesas compartilhadas.';
      case AppLanguage.italian:
        return '• Crea eventi per viaggi o riunioni con budget e monitora le spese condivise.';
      case AppLanguage.chinese:
        return '• 创建旅行或聚会活动，设置预算并跟踪共享支出。';
      case AppLanguage.japanese:
        return '• 旅行や集まりのイベントを作成し、予算を設定して共有支出を追跡します。';
      default:
        return '• Crea eventos para viajes o juntadas con presupuesto y controla gastos compartidos.';
    }
  }

  String get manualEventosP2 {
    switch (language) {
      case AppLanguage.english:
        return '• Use the person icon to add participants to the event.';
      case AppLanguage.portuguese:
        return '• Use o ícone de pessoa para adicionar participantes ao evento.';
      case AppLanguage.italian:
        return '• Usa l\'icona della persona per aggiungere partecipanti all\'evento.';
      case AppLanguage.chinese:
        return '• 使用人员图标向活动添加参与者。';
      case AppLanguage.japanese:
        return '• 人物アイコンを使用してイベントに参加者を追加します。';
      default:
        return '• Usa el ícono de persona para adjuntar participantes al evento.';
    }
  }

  String get manualEventosP3 {
    switch (language) {
      case AppLanguage.english:
        return '• Tap and hold on a participant to remove them (only if they have no expenses).';
      case AppLanguage.portuguese:
        return '• Pressione e segure um participante para removê-lo (apenas se não tiver despesas).';
      case AppLanguage.italian:
        return '• Tieni premuto su un partecipante per rimuoverlo (solo se non ha spese).';
      case AppLanguage.chinese:
        return '• 长按参与者可将其移除（仅当他们没有支出时）。';
      case AppLanguage.japanese:
        return '• 参加者を長押しして削除します（支出がない場合のみ）。';
      default:
        return '• Mantén presionado un participante para eliminarlo (solo si no tiene gastos).';
    }
  }

  String get manualEventosP4 {
    switch (language) {
      case AppLanguage.english:
        return '• Share the event with the share button to invite friends.';
      case AppLanguage.portuguese:
        return '• Compartilhe o evento com o botão de compartilhar para convidar amigos.';
      case AppLanguage.italian:
        return '• Condividi l\'evento con il pulsante di condivisione per invitare amici.';
      case AppLanguage.chinese:
        return '• 使用分享按钮分享活动以邀请朋友。';
      case AppLanguage.japanese:
        return '• 共有ボタンでイベントを共有して友達を招待します。';
      default:
        return '• Comparte el evento con el botón compartir para invitar amigos.';
    }
  }

  String get manualAnalyticsTitulo {
    switch (language) {
      case AppLanguage.english:
        return '8) Analytics';
      case AppLanguage.portuguese:
        return '8) Estatísticas';
      case AppLanguage.italian:
        return '8) Statistiche';
      case AppLanguage.chinese:
        return '8) 分析';
      case AppLanguage.japanese:
        return '8) 分析';
      default:
        return '8) Analíticas';
    }
  }

  String get manualAnalyticsP1 {
    switch (language) {
      case AppLanguage.english:
        return '• Access from Settings > Analytics to view app usage statistics.';
      case AppLanguage.portuguese:
        return '• Acesse em Configurações > Estatísticas para ver estatísticas de uso do app.';
      case AppLanguage.italian:
        return '• Accedi da Impostazioni > Statistiche per visualizzare le statistiche di utilizzo.';
      case AppLanguage.chinese:
        return '• 从设置 > 分析访问以查看应用程序使用统计信息。';
      case AppLanguage.japanese:
        return '• 設定 > 分析からアクセスしてアプリの使用統計を表示します。';
      default:
        return '• Accede desde Configuración > Analíticas para ver estadísticas de uso de la app.';
    }
  }

  String get manualAnalyticsP2 {
    switch (language) {
      case AppLanguage.english:
        return '• See how many transactions, events, and reports you\'ve created.';
      case AppLanguage.portuguese:
        return '• Veja quantas transações, eventos e relatórios você criou.';
      case AppLanguage.italian:
        return '• Vedi quante transazioni, eventi e rapporti hai creato.';
      case AppLanguage.chinese:
        return '• 查看您创建了多少交易、活动和报告。';
      case AppLanguage.japanese:
        return '• 作成したトランザクション、イベント、レポートの数を確認します。';
      default:
        return '• Ve cuántas transacciones, eventos e informes has creado.';
    }
  }
  // Manual de uso - Fin

  String get seleccionaFormatoReporte {
    switch (language) {
      case AppLanguage.english:
        return 'Select report format';
      case AppLanguage.portuguese:
        return 'Selecciona o formato do relatório';
      case AppLanguage.italian:
        return 'Seleziona il formato del rapporto';
      case AppLanguage.chinese:
        return '选择报告格式';
      case AppLanguage.japanese:
        return 'レポート種を選択';
      default:
        return 'Selecciona el formato de informe';
    }
  }

  String get exportar2 {
    switch (language) {
      case AppLanguage.english:
        return 'Export';
      case AppLanguage.portuguese:
        return 'Exportar';
      case AppLanguage.italian:
        return 'Esporta';
      case AppLanguage.chinese:
        return '导出';
      case AppLanguage.japanese:
        return 'エクスポート';
      default:
        return 'Exportar';
    }
  }

  String get mesActual {
    switch (language) {
      case AppLanguage.english:
        return 'Current Month';
      case AppLanguage.portuguese:
        return 'Mês Atual';
      case AppLanguage.italian:
        return 'Mese Corrente';
      case AppLanguage.chinese:
        return '当月';
      case AppLanguage.japanese:
        return '今月';
      default:
        return 'Mes actual';
    }
  }

  String get todoElAnio {
    switch (language) {
      case AppLanguage.english:
        return 'Entire Year';
      case AppLanguage.portuguese:
        return 'Todo o Ano';
      case AppLanguage.italian:
        return 'Intero Anno';
      case AppLanguage.chinese:
        return '整整一年';
      case AppLanguage.japanese:
        return '一年全部';
      default:
        return 'Todo el año';
    }
  }

  String get todosLosDatos {
    switch (language) {
      case AppLanguage.english:
        return 'All Data';
      case AppLanguage.portuguese:
        return 'Todos os Dados';
      case AppLanguage.italian:
        return 'Tutti i Dati';
      case AppLanguage.chinese:
        return '所有数据';
      case AppLanguage.japanese:
        return 'すべてのデータ';
      default:
        return 'Todos los datos';
    }
  }

  String get historiaiCompleto {
    switch (language) {
      case AppLanguage.english:
        return 'Complete History';
      case AppLanguage.portuguese:
        return 'Histórico Completo';
      case AppLanguage.italian:
        return 'Storico Completo';
      case AppLanguage.chinese:
        return '完整历史';
      case AppLanguage.japanese:
        return '完全な履歴';
      default:
        return 'Historial completo';
    }
  }

  String get noHayDatos {
    switch (language) {
      case AppLanguage.english:
        return 'No data for this year';
      case AppLanguage.portuguese:
        return 'Sem dados para este ano';
      case AppLanguage.italian:
        return 'Nessun dato per questo anno';
      case AppLanguage.chinese:
        return '此年没有数据';
      case AppLanguage.japanese:
        return '今年のデータはありません';
      default:
        return 'No hay datos para este año';
    }
  }

  String get noHayDatosExportar {
    switch (language) {
      case AppLanguage.english:
        return 'No data to export';
      case AppLanguage.portuguese:
        return 'Sem dados para exportar';
      case AppLanguage.italian:
        return 'Nessun dato da esportare';
      case AppLanguage.chinese:
        return '没有数据可导出';
      case AppLanguage.japanese:
        return 'エクスポートするデータがありません';
      default:
        return 'No hay datos para exportar';
    }
  }

  String get reporteAnualGenerado {
    switch (language) {
      case AppLanguage.english:
        return '✨ Annual report generated (Premium)';
      case AppLanguage.portuguese:
        return '✨ Relatório anual gerado (Premium)';
      case AppLanguage.italian:
        return '✨ Rapporto annuale generato (Premium)';
      case AppLanguage.chinese:
        return '✨ 年度报告已生成（高级）';
      case AppLanguage.japanese:
        return '✨ 年間レポートが生成されました（Premium）';
      default:
        return '✨ Informe anual generado (Premium)';
    }
  }

  String get historiaiCompletoExportado {
    switch (language) {
      case AppLanguage.english:
        return '✨ Complete history exported (Premium)';
      case AppLanguage.portuguese:
        return '✨ Histórico completo exportado (Premium)';
      case AppLanguage.italian:
        return '✨ Storico completo esportato (Premium)';
      case AppLanguage.chinese:
        return '✨ 完整历史已导出（高级）';
      case AppLanguage.japanese:
        return '✨ 完全な履歴がエクスポートされました（Premium）';
      default:
        return '✨ Historial completo exportado (Premium)';
    }
  }

  String get desbloquearPremium {
    switch (language) {
      case AppLanguage.english:
        return 'Unlock Premium';
      case AppLanguage.portuguese:
        return 'Desbloquear Premium';
      case AppLanguage.italian:
        return 'Sblocca Premium';
      case AppLanguage.chinese:
        return '解锁Premium';
      case AppLanguage.japanese:
        return 'Premiumの粗賊';
      default:
        return 'Desbloquea Premium';
    }
  }

  String get verMas {
    switch (language) {
      case AppLanguage.english:
        return 'See more';
      case AppLanguage.portuguese:
        return 'Ver mais';
      case AppLanguage.italian:
        return 'Vedi altro';
      case AppLanguage.chinese:
        return '查看更多';
      case AppLanguage.japanese:
        return 'もっと詳を詳を見る';
      default:
        return 'Ver más';
    }
  }

  String get categoriasPersonalizadas {
    switch (language) {
      case AppLanguage.english:
        return '📂 Custom categories';
      case AppLanguage.portuguese:
        return '📂 Categorias personalizadas';
      case AppLanguage.italian:
        return '📂 Categorie personalizzate';
      case AppLanguage.chinese:
        return '📂 自定义类别';
      case AppLanguage.japanese:
        return '📂 カスタムカテゴリ';
      default:
        return '📂 Categorías personalizadas';
    }
  }

  String get monedasMultiplesBanner {
    switch (language) {
      case AppLanguage.english:
        return '💱 Multiple currencies';
      case AppLanguage.portuguese:
        return '💱 Múltiplas moedas';
      case AppLanguage.italian:
        return '💱 Valute multiple';
      case AppLanguage.chinese:
        return '💱 多种货币';
      case AppLanguage.japanese:
        return '💱 複数通貨';
      default:
        return '💱 Monedas múltiples';
    }
  }

  String get reportesAvanzados {
    switch (language) {
      case AppLanguage.english:
        return '📊 Advanced reports';
      case AppLanguage.portuguese:
        return '📊 Relatórios avançados';
      case AppLanguage.italian:
        return '📊 Rapporti avanzati';
      case AppLanguage.chinese:
        return '📊 高级报告';
      case AppLanguage.japanese:
        return '📊 高度なレポート';
      default:
        return '📊 Informes avanzados';
    }
  }

  String get marketingAfiliacion {
    switch (language) {
      case AppLanguage.english:
        return '🤝 Affiliate Marketing';
      case AppLanguage.portuguese:
        return '🤝 Marketing de Afiliação';
      case AppLanguage.italian:
        return '🤝 Marketing di Affiliazione';
      case AppLanguage.chinese:
        return '🤝 会员营销';
      case AppLanguage.japanese:
        return '🤝 アフィリエイトマーケティング';
      default:
        return '🤝 Marketing de Afiliación';
    }
  }

  String get recomendacionesFinancieras {
    switch (language) {
      case AppLanguage.english:
        return 'Financial Recommendations';
      case AppLanguage.portuguese:
        return 'Recomendações Financeiras';
      case AppLanguage.italian:
        return 'Raccomandazioni Finanziarie';
      case AppLanguage.chinese:
        return '财务建议';
      case AppLanguage.japanese:
        return '財務推気';
      default:
        return 'Recomendaciones Financieras';
    }
  }

  String get recomendacionesDescripcion {
    switch (language) {
      case AppLanguage.english:
        return 'Get personalized recommendations based on your spending patterns';
      case AppLanguage.portuguese:
        return 'Obtenha recomendações personalizadas com base em seus padrões de gastos';
      case AppLanguage.italian:
        return 'Ottieni raccomandazioni personalizzate in base ai tuoi modelli di spesa';
      case AppLanguage.chinese:
        return '根据你的支出模式获得个性化建议';
      case AppLanguage.japanese:
        return '你の支出パターンに基づいたカスタム財務推気を受ける';
      default:
        return 'Obtén recomendaciones personalizadas basadas en tus patrones de gasto';
    }
  }

  String get tarjetasCredito {
    switch (language) {
      case AppLanguage.english:
        return 'Credit Cards';
      case AppLanguage.portuguese:
        return 'Cartões de Crédito';
      case AppLanguage.italian:
        return 'Carte di Credito';
      case AppLanguage.chinese:
        return '信用卡';
      case AppLanguage.japanese:
        return 'クレジットカード';
      default:
        return 'Tarjetas de Crédito';
    }
  }

  String get seguros {
    switch (language) {
      case AppLanguage.english:
        return 'Insurance';
      case AppLanguage.portuguese:
        return 'Seguros';
      case AppLanguage.italian:
        return 'Assicurazioni';
      case AppLanguage.chinese:
        return '保险';
      case AppLanguage.japanese:
        return '保険';
      default:
        return 'Seguros';
    }
  }

  String get cuentasAhorro {
    switch (language) {
      case AppLanguage.english:
        return 'Savings Accounts';
      case AppLanguage.portuguese:
        return 'Contas de Poupança';
      case AppLanguage.italian:
        return 'Conti di Risparmio';
      case AppLanguage.chinese:
        return '储蓄账户';
      case AppLanguage.japanese:
        return '貯蓄口座';
      default:
        return 'Cuentas de Ahorro';
    }
  }

  String get recomendacionSalud {
    switch (language) {
      case AppLanguage.english:
        return 'We noticed high health expenses. Consider getting health insurance with better coverage.';
      case AppLanguage.portuguese:
        return 'Notamos despesas de saúde elevadas. Considere obter um seguro de saúde com melhor cobertura.';
      case AppLanguage.italian:
        return 'Abbiamo notato spese sanitarie elevate. Considera di ottenere un\'assicurazione sanitaria con una migliore copertura.';
      case AppLanguage.chinese:
        return '我们注意到您的医疗保险费用很高。考虑不購什么熬少一个覆盖更广的医疗保险。';
      case AppLanguage.japanese:
        return '你の医療費を関連で高い支出を注意しました。より优れた覆稄を提供する医療保险からの伟を考慮してください。';
      default:
        return 'Notamos gastos altos en salud. Considera contratar un seguro médico con mejor cobertura.';
    }
  }

  String get recomendacionTransporte {
    switch (language) {
      case AppLanguage.english:
        return 'Your transportation expenses are significant. We recommend credit cards with cashback on fuel.';
      case AppLanguage.portuguese:
        return 'Suas despesas de transporte são significativas. Recomendamos cartões de crédito com cashback em combustível.';
      case AppLanguage.italian:
        return 'Le tue spese di trasporto sono significative. Raccomandiamo carte di credito con cashback sul carburante.';
      default:
        return 'Tus gastos de transporte son significativos. Recomendamos tarjetas de crédito con cashback en combustible.';
    }
  }

  String get recomendacionAhorro {
    switch (language) {
      case AppLanguage.english:
        return 'Your savings capacity is excellent! Consider opening a high-yield savings account.';
      case AppLanguage.portuguese:
        return 'Sua capacidade de poupança é excelente! Considere abrir uma conta de poupança de alto rendimento.';
      case AppLanguage.italian:
        return 'La tua capacità di risparmio è eccellente! Considera l\'apertura di un conto di risparmio ad alto rendimento.';
      case AppLanguage.chinese:
        return '您的储蓄能力坏！考虑不購什么一个高收伊的储蓄账户。';
      case AppLanguage.japanese:
        return '您の貯蓄能力は儯秀です！高利始储蓄口座を開設することを一拧する。';
      default:
        return '¡Tu capacidad de ahorro es excelente! Considera abrir una cuenta de ahorro con mejores tasas de interés.';
    }
  }

  String get verOfertas {
    switch (language) {
      case AppLanguage.english:
        return 'View Offers';
      case AppLanguage.portuguese:
        return 'Ver Ofertas';
      case AppLanguage.italian:
        return 'Vedi Offerte';
      case AppLanguage.chinese:
        return '查看推推';
      case AppLanguage.japanese:
        return 'オファーを表示';
      default:
        return 'Ver Ofertas';
    }
  }

  String get serviciosRecomendados {
    switch (language) {
      case AppLanguage.english:
        return 'Recommended Services';
      case AppLanguage.portuguese:
        return 'Serviços Recomendados';
      case AppLanguage.italian:
        return 'Servizi Consigliati';
      case AppLanguage.chinese:
        return '推荐服务';
      case AppLanguage.japanese:
        return '推奨サービス';
      default:
        return 'Servicios Recomendados';
    }
  }

  String get extraccionDeAhorro {
    switch (language) {
      case AppLanguage.english:
        return 'Withdrawal from Savings';
      case AppLanguage.portuguese:
        return 'Extração de Poupança';
      case AppLanguage.italian:
        return 'Prelievo dai Risparmi';
      case AppLanguage.chinese:
        return '从储蓄中提取';
      case AppLanguage.japanese:
        return '貯蓄からの引き出し';
      default:
        return 'Extracción de ahorro';
    }
  }

  String get extraer {
    switch (language) {
      case AppLanguage.english:
        return 'Withdraw';
      case AppLanguage.portuguese:
        return 'Extrair';
      case AppLanguage.italian:
        return 'Ritira';
      case AppLanguage.chinese:
        return '提取';
      case AppLanguage.japanese:
        return '引き出し';
      default:
        return 'Extraer';
    }
  }

  String get ingresaMontoValido {
    switch (language) {
      case AppLanguage.english:
        return 'Please enter a valid amount to withdraw';
      case AppLanguage.portuguese:
        return 'Por favor, insira um valor válido para extrair';
      case AppLanguage.italian:
        return 'Inserisci un importo valido da ritirare';
      case AppLanguage.chinese:
        return '请输入有效提取金额';
      case AppLanguage.japanese:
        return '有効な引き出し金額を輳るしてください';
      default:
        return 'Ingresa un monto válido para extraer';
    }
  }

  String get completaTodosCampos {
    switch (language) {
      case AppLanguage.english:
        return 'Please complete all fields correctly';
      case AppLanguage.portuguese:
        return 'Por favor, complete todos os campos corretamente';
      case AppLanguage.italian:
        return 'Completa tutti i campi correttamente';
      case AppLanguage.chinese:
        return '请正确完成所有字段';
      case AppLanguage.japanese:
        return 'pleaseご文攷われた欄を上造めに入った';
      default:
        return 'Por favor completa todos los campos correctamente';
    }
  }

  String get gastoFijoAgregado {
    switch (language) {
      case AppLanguage.english:
        return 'Fixed expense added successfully';
      case AppLanguage.portuguese:
        return 'Despesa fixa adicionada com sucesso';
      case AppLanguage.italian:
        return 'Spesa fissa aggiunta con successo';
      case AppLanguage.chinese:
        return '固定支出成功添加';
      case AppLanguage.japanese:
        return '固定支出を正正常に追加しました';
      default:
        return 'Gasto fijo agregado correctamente';
    }
  }

  String get gastoFijoActualizado {
    switch (language) {
      case AppLanguage.english:
        return 'Fixed expense updated';
      case AppLanguage.portuguese:
        return 'Despesa fixa atualizada';
      case AppLanguage.italian:
        return 'Spesa fissa aggiornata';
      case AppLanguage.chinese:
        return '固定支出已更新';
      case AppLanguage.japanese:
        return '固定支出が更新されました';
      default:
        return 'Gasto fijo actualizado';
    }
  }

  String get gastoFijoEliminado {
    switch (language) {
      case AppLanguage.english:
        return 'Fixed expense deleted';
      case AppLanguage.portuguese:
        return 'Despesa fixa excluída';
      case AppLanguage.italian:
        return 'Spesa fissa eliminata';
      case AppLanguage.chinese:
        return '固定支出已删除';
      case AppLanguage.japanese:
        return '固定支出が削除されました';
      default:
        return 'Gasto fijo eliminado';
    }
  }

  String get categoriaAgregada {
    switch (language) {
      case AppLanguage.english:
        return 'Category added';
      case AppLanguage.portuguese:
        return 'Categoria adicionada';
      case AppLanguage.italian:
        return 'Categoria aggiunta';
      case AppLanguage.chinese:
        return '类别已添加';
      case AppLanguage.japanese:
        return 'カテゴリが追加されました';
      default:
        return 'Categoría agregada';
    }
  }

  String get categoriaEliminada {
    switch (language) {
      case AppLanguage.english:
        return 'Category deleted';
      case AppLanguage.portuguese:
        return 'Categoria excluída';
      case AppLanguage.italian:
        return 'Categoria eliminata';
      case AppLanguage.chinese:
        return '类别已削除';
      case AppLanguage.japanese:
        return 'カテゴリが削除されました';
      default:
        return 'Categoría eliminada';
    }
  }

  String get errorAlGenerar {
    switch (language) {
      case AppLanguage.english:
        return 'Error generating report';
      case AppLanguage.portuguese:
        return 'Erro ao gerar relatório';
      case AppLanguage.italian:
        return 'Errore nella generazione del rapporto';
      case AppLanguage.chinese:
        return '生成报告时错误';
      case AppLanguage.japanese:
        return 'レポート生成時のエラー';
      default:
        return 'Error al generar informe';
    }
  }

  String get notificacionesInicializadas {
    switch (language) {
      case AppLanguage.english:
        return 'Notifications initialized successfully';
      case AppLanguage.portuguese:
        return 'Notificações inicializadas com sucesso';
      case AppLanguage.italian:
        return 'Notifiche inizializzate correttamente';
      case AppLanguage.chinese:
        return '通知成功初始化';
      case AppLanguage.japanese:
        return '通知が正正常に初始化されました';
      default:
        return 'Notificaciones inicializadas correctamente';
    }
  }

  String get errorInicializarNotificaciones {
    switch (language) {
      case AppLanguage.english:
        return 'Error initializing notifications';
      case AppLanguage.portuguese:
        return 'Erro ao inicializar notificações';
      case AppLanguage.italian:
        return 'Errore nell\'inizializzazione delle notifiche';
      case AppLanguage.chinese:
        return '初始化通知时错误';
      case AppLanguage.japanese:
        return '通知初期化時のエラー';
      default:
        return 'Error al inicializar notificaciones';
    }
  }

  String get novedadesPorEmail {
    switch (language) {
      case AppLanguage.english:
        return 'News by Email';
      case AppLanguage.portuguese:
        return 'Novidades por Email';
      case AppLanguage.italian:
        return 'Novità via Email';
      case AppLanguage.chinese:
        return '电子邮件新闻';
      case AppLanguage.japanese:
        return 'メールでのニュース';
      default:
        return 'Novedades por Email';
    }
  }

  String get recibirActualizacionesEmail {
    switch (language) {
      case AppLanguage.english:
        return 'Receive updates and financial tips';
      case AppLanguage.portuguese:
        return 'Receba atualizações e dicas financeiras';
      case AppLanguage.italian:
        return 'Ricevi aggiornamenti e consigli finanziari';
      case AppLanguage.chinese:
        return '接收更新和财务提示';
      case AppLanguage.japanese:
        return '更新と財務のヒントを受け取る';
      default:
        return 'Recibe actualizaciones y consejos financieros';
    }
  }

  String get suscriptoNovedades {
    switch (language) {
      case AppLanguage.english:
        return '✅ You subscribed to news by email';
      case AppLanguage.portuguese:
        return '✅ Você se inscreveu nas novidades por email';
      case AppLanguage.italian:
        return '✅ Ti sei iscritto alle novità via email';
      case AppLanguage.chinese:
        return '✅ 您已订阅电子邮件新闻';
      case AppLanguage.japanese:
        return '✅ メールニュースを購読しました';
      default:
        return '✅ Te suscribiste a las novedades por email';
    }
  }

  String get bajaSuscripcion {
    switch (language) {
      case AppLanguage.english:
        return '❌ You unsubscribed from news';
      case AppLanguage.portuguese:
        return '❌ Você cancelou a inscrição nas novidades';
      case AppLanguage.italian:
        return '❌ Ti sei disiscritto dalle novità';
      case AppLanguage.chinese:
        return '❌ 您已取消订阅新闻';
      case AppLanguage.japanese:
        return '❌ ニュースの購読を解除しました';
      default:
        return '❌ Te diste de baja de las novedades';
    }
  }

  String get recordatorioGastoFijo {
    switch (language) {
      case AppLanguage.english:
        return '⏰ Fixed Expense Reminder';
      case AppLanguage.portuguese:
        return '⏰ Lembrete de Despesa Fixa';
      case AppLanguage.italian:
        return '⏰ Promemoria Spesa Fissa';
      case AppLanguage.chinese:
        return '⏰ 固定支出提醒';
      case AppLanguage.japanese:
        return '⏰ 固定支出の思い出し';
      default:
        return '⏰ Recordatorio de Gasto Fijo';
    }
  }

  String get vence {
    switch (language) {
      case AppLanguage.english:
        return 'Due on day';
      case AppLanguage.portuguese:
        return 'Vence no dia';
      case AppLanguage.italian:
        return 'Scadenza il giorno';
      case AppLanguage.chinese:
        return '拉敢调上';
      case AppLanguage.japanese:
        return '子会様日が揺んでいる';
      default:
        return 'vence el día';
    }
  }

  String get monto2 {
    switch (language) {
      case AppLanguage.english:
        return 'Amount';
      case AppLanguage.portuguese:
        return 'Valor';
      case AppLanguage.italian:
        return 'Importo';
      case AppLanguage.chinese:
        return '金额';
      case AppLanguage.japanese:
        return '金額';
      default:
        return 'Monto';
    }
  }

  String get nuevaCategoria {
    switch (language) {
      case AppLanguage.english:
        return 'New Category';
      case AppLanguage.portuguese:
        return 'Nova Categoria';
      case AppLanguage.italian:
        return 'Nuova Categoria';
      case AppLanguage.chinese:
        return '新类别';
      case AppLanguage.japanese:
        return '新しいカテゴリ';
      default:
        return 'Nueva Categoría';
    }
  }

  String get agregar {
    switch (language) {
      case AppLanguage.english:
        return 'Add';
      case AppLanguage.portuguese:
        return 'Adicionar';
      case AppLanguage.italian:
        return 'Aggiungi';
      case AppLanguage.chinese:
        return '添加';
      case AppLanguage.japanese:
        return '追加';
      default:
        return 'Agregar';
    }
  }

  String get noObtieneMonedasDisponibles {
    switch (language) {
      case AppLanguage.english:
        return 'You already have all available currencies';
      case AppLanguage.portuguese:
        return 'Você já tem todas as moedas disponíveis';
      case AppLanguage.italian:
        return 'Hai già tutte le valute disponibili';
      case AppLanguage.chinese:
        return '您已经有所有可用货币';
      case AppLanguage.japanese:
        return '你はすでにすべての利用可能な通貨を持っています';
      default:
        return 'Ya tienes todas las monedas disponibles';
    }
  }

  String get noObtieneMonedasActiva {
    switch (language) {
      case AppLanguage.english:
        return 'Cannot delete the active currency';
      case AppLanguage.portuguese:
        return 'Não é possível excluir a moeda ativa';
      case AppLanguage.italian:
        return 'Impossibile eliminare la valuta attiva';
      case AppLanguage.chinese:
        return '无法削除活动中的货币';
      case AppLanguage.japanese:
        return 'アクティブ通貨を削除できません';
      default:
        return 'No puedes eliminar la moneda activa';
    }
  }

  String get monedaAgregada {
    switch (language) {
      case AppLanguage.english:
        return 'Currency added';
      case AppLanguage.portuguese:
        return 'Moeda adicionada';
      case AppLanguage.italian:
        return 'Valuta aggiunta';
      case AppLanguage.chinese:
        return '货币已添加';
      case AppLanguage.japanese:
        return '通貨が追加されました';
      default:
        return 'Moneda agregada';
    }
  }

  String get monedaEliminada {
    switch (language) {
      case AppLanguage.english:
        return 'Currency deleted';
      case AppLanguage.portuguese:
        return 'Moeda excluída';
      case AppLanguage.italian:
        return 'Valuta eliminata';
      case AppLanguage.chinese:
        return '货币已削除';
      case AppLanguage.japanese:
        return '通貨が削除されました';
      default:
        return 'Moneda eliminada';
    }
  }

  String get monedaCambiada {
    switch (language) {
      case AppLanguage.english:
        return 'Currency changed to';
      case AppLanguage.portuguese:
        return 'Moeda alterada para';
      case AppLanguage.italian:
        return 'Valuta modificata in';
      case AppLanguage.chinese:
        return '货币已更改为';
      case AppLanguage.japanese:
        return '通貨が誈更されました';
      default:
        return 'Moneda cambiada a';
    }
  }

  String get agregarMoneda {
    switch (language) {
      case AppLanguage.english:
        return 'Add Currency';
      case AppLanguage.portuguese:
        return 'Adicionar Moeda';
      case AppLanguage.italian:
        return 'Aggiungi Valuta';
      case AppLanguage.chinese:
        return '添加货币';
      case AppLanguage.japanese:
        return '通貨を追加';
      default:
        return 'Agregar Moneda';
    }
  }

  String get activa {
    switch (language) {
      case AppLanguage.english:
        return 'active';
      case AppLanguage.portuguese:
        return 'ativa';
      case AppLanguage.italian:
        return 'attiva';
      case AppLanguage.chinese:
        return '活动';
      case AppLanguage.japanese:
        return 'アクティブ';
      default:
        return 'activa';
    }
  }

  // Nombres de meses
  List<String> get nombresMeses {
    switch (language) {
      case AppLanguage.english:
        return ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      case AppLanguage.portuguese:
        return ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
      case AppLanguage.italian:
        return ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];
      case AppLanguage.chinese:
        return ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
      case AppLanguage.japanese:
        return ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
      default:
        return ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    }
  }

  // Pantalla de ahorros
  String get ahorrosAcumulados {
    switch (language) {
      case AppLanguage.english:
        return 'Accumulated Savings';
      case AppLanguage.portuguese:
        return 'Economias Acumuladas';
      case AppLanguage.italian:
        return 'Risparmi Accumulati';
      case AppLanguage.chinese:
        return '累计储蓄';
      case AppLanguage.japanese:
        return '累積貯蓄';
      default:
        return 'Ahorros Acumulados';
    }
  }

  String get totalAcumuladoMeses {
    switch (language) {
      case AppLanguage.english:
        return 'Total accumulated from all months';
      case AppLanguage.portuguese:
        return 'Total acumulado de todos os meses';
      case AppLanguage.italian:
        return 'Totale accumulato da tutti i mesi';
      case AppLanguage.chinese:
        return '所有月份的累计总额';
      case AppLanguage.japanese:
        return 'すべての月の累計合計';
      default:
        return 'Total acumulado de todos los meses';
    }
  }

  String get extraccionDinero {
    switch (language) {
      case AppLanguage.english:
        return 'Withdraw Money';
      case AppLanguage.portuguese:
        return 'Saque de Dinheiro';
      case AppLanguage.italian:
        return 'Prelievo di Denaro';
      case AppLanguage.chinese:
        return '提取资金';
      case AppLanguage.japanese:
        return '資金の引き出し';
      default:
        return 'Extracción de dinero';
    }
  }

  String get sinRegistrosAhorros {
    switch (language) {
      case AppLanguage.english:
        return 'No savings records';
      case AppLanguage.portuguese:
        return 'Sem registros de poupança';
      case AppLanguage.italian:
        return 'Nessun record di risparmio';
      case AppLanguage.chinese:
        return '没有储蓄记录';
      case AppLanguage.japanese:
        return '貯蓄記録なし';
      default:
        return 'Sin registros de ahorros';
    }
  }

  String get registraTransaccionesAhorros {
    switch (language) {
      case AppLanguage.english:
        return 'Record transactions to generate savings per month';
      case AppLanguage.portuguese:
        return 'Registre transações para gerar economias por mês';
      case AppLanguage.italian:
        return 'Registra le transazioni per generare risparmi al mese';
      case AppLanguage.chinese:
        return '记录交易以按月生成储蓄';
      case AppLanguage.japanese:
        return 'トランザクションを記録して、月ごとに節約を生成します';
      default:
        return 'Registra transacciones para generar ahorros por mes';
    }
  }

  String get historialAhorrosMes {
    switch (language) {
      case AppLanguage.english:
        return 'Savings History by Month';
      case AppLanguage.portuguese:
        return 'Histórico de Poupança por Mês';
      case AppLanguage.italian:
        return 'Storico Risparmi per Mese';
      case AppLanguage.chinese:
        return '月度储蓄历史';
      case AppLanguage.japanese:
        return '月別貯蓄履歴';
      default:
        return 'Historial de Ahorros por Mes';
    }
  }

  String get extraccionAhorro {
    switch (language) {
      case AppLanguage.english:
        return 'Savings Withdrawal';
      case AppLanguage.portuguese:
        return 'Retirada de Poupança';
      case AppLanguage.italian:
        return 'Prelievo dai Risparmi';
      case AppLanguage.chinese:
        return '储蓄提取';
      case AppLanguage.japanese:
        return '貯蓄の引き出し';
      default:
        return 'Extracción de ahorro';
    }
  }

  String get usoReservas {
    switch (language) {
      case AppLanguage.english:
        return 'Use of reserves';
      case AppLanguage.portuguese:
        return 'Uso de reservas';
      case AppLanguage.italian:
        return 'Utilizzo delle riserve';
      case AppLanguage.chinese:
        return '储备金使用';
      case AppLanguage.japanese:
        return '予備金の使用';
      default:
        return 'Uso de reservas';
    }
  }

  String get balancePositivo {
    switch (language) {
      case AppLanguage.english:
        return 'Positive balance';
      case AppLanguage.portuguese:
        return 'Saldo positivo';
      case AppLanguage.italian:
        return 'Saldo positivo';
      case AppLanguage.chinese:
        return '正余额';
      case AppLanguage.japanese:
        return 'ポジティブバランス';
      default:
        return 'Balance positivo';
    }
  }

  String get balanceNegativo {
    switch (language) {
      case AppLanguage.english:
        return 'Negative balance';
      case AppLanguage.portuguese:
        return 'Saldo negativo';
      case AppLanguage.italian:
        return 'Saldo negativo';
      case AppLanguage.chinese:
        return '负余额';
      case AppLanguage.japanese:
        return 'ネガティブバランス';
      default:
        return 'Balance negativo';
    }
  }

  String get mesDesconocido {
    switch (language) {
      case AppLanguage.english:
        return 'Unknown month';
      case AppLanguage.portuguese:
        return 'Mês desconhecido';
      case AppLanguage.italian:
        return 'Mese sconosciuto';
      case AppLanguage.chinese:
        return '未知月份';
      case AppLanguage.japanese:
        return '不明な月';
      default:
        return 'Mes desconocido';
    }
  }

  // Pantalla de gráficos
  String get distribucionMensual {
    switch (language) {
      case AppLanguage.english:
        return '📅 Monthly Distribution';
      case AppLanguage.portuguese:
        return '📅 Distribuição Mensal';
      case AppLanguage.italian:
        return '📅 Distribuzione Mensile';
      case AppLanguage.chinese:
        return '📅 月度分布';
      case AppLanguage.japanese:
        return '📅 月間分布';
      default:
        return '📅 Distribución Mensual';
    }
  }

  String get distribucionAnual {
    switch (language) {
      case AppLanguage.english:
        return '📆 Annual Distribution';
      case AppLanguage.portuguese:
        return '📆 Distribuição Anual';
      case AppLanguage.italian:
        return '📆 Distribuzione Annuale';
      case AppLanguage.chinese:
        return '📆 年度分布';
      case AppLanguage.japanese:
        return '📆 年間分布';
      default:
        return '📆 Distribución Anual';
    }
  }

  // Etiquetas de gráficos
  String get ingresoLabel {
    switch (language) {
      case AppLanguage.english:
        return 'Income';
      case AppLanguage.portuguese:
        return 'Receita';
      case AppLanguage.italian:
        return 'Reddito';
      case AppLanguage.chinese:
        return '收入';
      case AppLanguage.japanese:
        return '収入';
      default:
        return 'Ingresos';
    }
  }

  String get sinDatos {
    switch (language) {
      case AppLanguage.english:
        return 'No data';
      case AppLanguage.portuguese:
        return 'Sem dados';
      case AppLanguage.italian:
        return 'Nessun dato';
      case AppLanguage.chinese:
        return '没有数据';
      case AppLanguage.japanese:
        return 'データなし';
      default:
        return 'Sin datos';
    }
  }

  // Pantalla de Gastos Fijos
  String get gastosFijosTitle {
    switch (language) {
      case AppLanguage.english:
        return 'Fixed Expenses';
      case AppLanguage.portuguese:
        return 'Despesas Fixas';
      case AppLanguage.italian:
        return 'Spese Fisse';
      case AppLanguage.chinese:
        return '固定费用';
      case AppLanguage.japanese:
        return '固定費用';
      default:
        return 'Gastos Fijos';
    }
  }

  String get sinGastosFijos {
    switch (language) {
      case AppLanguage.english:
        return 'No fixed expenses registered';
      case AppLanguage.portuguese:
        return 'Sem despesas fixas registradas';
      case AppLanguage.italian:
        return 'Nessuna spesa fissa registrata';
      case AppLanguage.chinese:
        return '未注册固定费用';
      case AppLanguage.japanese:
        return '固定費用が登録されていません';
      default:
        return 'Sin gastos fijos registrados';
    }
  }

  String get agregarGastoFijo {
    switch (language) {
      case AppLanguage.english:
        return 'Add Fixed Expense';
      case AppLanguage.portuguese:
        return 'Adicionar Despesa Fixa';
      case AppLanguage.italian:
        return 'Aggiungi Spesa Fissa';
      case AppLanguage.chinese:
        return '添加固定费用';
      case AppLanguage.japanese:
        return '固定費用を追加';
      default:
        return 'Agregar Gasto Fijo';
    }
  }

  String get editar {
    switch (language) {
      case AppLanguage.english:
        return 'Edit';
      case AppLanguage.portuguese:
        return 'Editar';
      case AppLanguage.italian:
        return 'Modifica';
      case AppLanguage.chinese:
        return '编辑';
      case AppLanguage.japanese:
        return '編集';
      default:
        return 'Editar';
    }
  }

  // Pantalla Premium
  String get funcionesPremiumActivas {
    switch (language) {
      case AppLanguage.english:
        return 'Active Premium Features';
      case AppLanguage.portuguese:
        return 'Recursos Premium Ativos';
      case AppLanguage.italian:
        return 'Funzioni Premium Attive';
      case AppLanguage.chinese:
        return '活跃的高级功能';
      case AppLanguage.japanese:
        return 'アクティブなプレミアム機能';
      default:
        return 'Funciones Premium Activas';
    }
  }

  String get sinPublicidad {
    switch (language) {
      case AppLanguage.english:
        return 'No Ads';
      case AppLanguage.portuguese:
        return 'Sem Anúncios';
      case AppLanguage.italian:
        return 'Senza Pubblicità';
      case AppLanguage.chinese:
        return '无广告';
      case AppLanguage.japanese:
        return '広告なし';
      default:
        return 'Sin Publicidad';
    }
  }

  String get sinPublicidadDesc {
    switch (language) {
      case AppLanguage.english:
        return 'Completely ad-free experience';
      case AppLanguage.portuguese:
        return 'Experiência completamente livre de anúncios';
      case AppLanguage.italian:
        return 'Esperienza completamente senza pubblicità';
      case AppLanguage.chinese:
        return '完全无广告体验';
      case AppLanguage.japanese:
        return '完全な広告なし体験';
      default:
        return 'Experiencia completamente libre de anuncios';
    }
  }

  String get backupNube {
    switch (language) {
      case AppLanguage.english:
        return 'Cloud Backup';
      case AppLanguage.portuguese:
        return 'Backup na Nuvem';
      case AppLanguage.italian:
        return 'Backup nel Cloud';
      case AppLanguage.chinese:
        return '云备份';
      case AppLanguage.japanese:
        return 'クラウドバックアップ';
      default:
        return 'Backup en la Nube';
    }
  }

  String get backupNubeDesc {
    switch (language) {
      case AppLanguage.english:
        return 'Sync your data across all devices';
      case AppLanguage.portuguese:
        return 'Sincroniza tus datos en todos tus dispositivos';
      case AppLanguage.italian:
        return 'Sincronizza i tuoi dati su tutti i dispositivi';
      case AppLanguage.chinese:
        return '跨所有设备同步数据';
      case AppLanguage.japanese:
        return 'すべてのデバイスでデータを同期';
      default:
        return 'Sincroniza tus datos en todos tus dispositivos';
    }
  }

  String get analisisAvanzados {
    switch (language) {
      case AppLanguage.english:
        return 'Advanced Analytics';
      case AppLanguage.portuguese:
        return 'Análises Avançadas';
      case AppLanguage.italian:
        return 'Analisi Avanzate';
      case AppLanguage.chinese:
        return '高级分析';
      case AppLanguage.japanese:
        return '高度な分析';
      default:
        return 'Análisis Avanzados';
    }
  }

  String get analisisAvanzadosDesc {
    switch (language) {
      case AppLanguage.english:
        return 'Detailed charts and financial projections';
      case AppLanguage.portuguese:
        return 'Gráficos detallados e projeções financeiras';
      case AppLanguage.italian:
        return 'Grafici dettagliati e proiezioni finanziarie';
      case AppLanguage.chinese:
        return '详细的图表和财务预测';
      case AppLanguage.japanese:
        return '詳細なチャートと財務予測';
      default:
        return 'Gráficos detallados y proyecciones financieras';
    }
  }

  String get soportePrioritario {
    switch (language) {
      case AppLanguage.english:
        return 'Priority Support';
      case AppLanguage.portuguese:
        return 'Suporte Prioritário';
      case AppLanguage.italian:
        return 'Supporto Prioritario';
      case AppLanguage.chinese:
        return '优先支持';
      case AppLanguage.japanese:
        return '優先サポート';
      default:
        return 'Soporte Prioritario';
    }
  }

  String get soportePrioritarioDesc {
    switch (language) {
      case AppLanguage.english:
        return 'Personalized attention and quick responses';
      case AppLanguage.portuguese:
        return 'Atención personalizada y respuestas rápidas';
      case AppLanguage.italian:
        return 'Attenzione personalizzata e risposte rapide';
      case AppLanguage.chinese:
        return '个性化关注和快速响应';
      case AppLanguage.japanese:
        return 'パーソナライズされた注意と迅速な応答';
      default:
        return 'Atención personalizada y respuestas rápidas';
    }
  }

  String get restaurarCompras {
    switch (language) {
      case AppLanguage.english:
        return 'Restore Purchases';
      case AppLanguage.portuguese:
        return 'Restaurar Compras';
      case AppLanguage.italian:
        return 'Ripristina Acquisti';
      case AppLanguage.chinese:
        return '恢复购买';
      case AppLanguage.japanese:
        return '購入を復元';
      default:
        return 'Restaurar Compras';
    }
  }

  String get yaCompraste {
    switch (language) {
      case AppLanguage.english:
        return 'Already purchased? Restore purchases';
      case AppLanguage.portuguese:
        return '¿Já compraste? Restaurar compras';
      case AppLanguage.italian:
        return 'Hai già acquistato? Ripristina acquisti';
      case AppLanguage.chinese:
        return '已购买？恢复购买';
      case AppLanguage.japanese:
        return 'すでに購入しましたか？ 購入を復元';
      default:
        return '¿Ya compraste? Restaurar compras';
    }
  }

  // === PERFIL: Botones y Acciones ===
  
  String get seleccionarFoto {
    switch (language) {
      case AppLanguage.english:
        return 'Select Photo';
      case AppLanguage.portuguese:
        return 'Selecionar Foto';
      case AppLanguage.italian:
        return 'Seleziona Foto';
      case AppLanguage.chinese:
        return '选择照片';
      case AppLanguage.japanese:
        return '写真を選択';
      default:
        return 'Seleccionar foto';
    }
  }

  String get tomarFoto {
    switch (language) {
      case AppLanguage.english:
        return 'Take Photo';
      case AppLanguage.portuguese:
        return 'Tirar Foto';
      case AppLanguage.italian:
        return 'Scatta Foto';
      case AppLanguage.chinese:
        return '拍照';
      case AppLanguage.japanese:
        return '写真を撮る';
      default:
        return 'Tomar foto';
    }
  }

  String get galeria {
    switch (language) {
      case AppLanguage.english:
        return 'Gallery';
      case AppLanguage.portuguese:
        return 'Galeria';
      case AppLanguage.italian:
        return 'Galleria';
      case AppLanguage.chinese:
        return '图库';
      case AppLanguage.japanese:
        return 'ギャラリー';
      default:
        return 'Galería';
    }
  }

  String get seleccionarDeGaleria {
    switch (language) {
      case AppLanguage.english:
        return 'Select from Gallery';
      case AppLanguage.portuguese:
        return 'Selecionar da Galeria';
      case AppLanguage.italian:
        return 'Seleziona dalla Galleria';
      case AppLanguage.chinese:
        return '从图库选择';
      case AppLanguage.japanese:
        return 'ギャラリーから選択';
      default:
        return 'Seleccionar de galería';
    }
  }

  String get guardarCambios {
    switch (language) {
      case AppLanguage.english:
        return 'Save Changes';
      case AppLanguage.portuguese:
        return 'Salvar Alterações';
      case AppLanguage.italian:
        return 'Salva Modifiche';
      case AppLanguage.chinese:
        return '保存更改';
      case AppLanguage.japanese:
        return '変更を保存';
      default:
        return 'Guardar cambios';
    }
  }

  String get cambiarFoto {
    switch (language) {
      case AppLanguage.english:
        return 'Change Photo';
      case AppLanguage.portuguese:
        return 'Mudar Foto';
      case AppLanguage.italian:
        return 'Cambia Foto';
      case AppLanguage.chinese:
        return '更换照片';
      case AppLanguage.japanese:
        return '写真を変更';
      default:
        return 'Cambiar foto';
    }
  }

  String get eliminarFoto {
    switch (language) {
      case AppLanguage.english:
        return 'Delete Photo';
      case AppLanguage.portuguese:
        return 'Excluir Foto';
      case AppLanguage.italian:
        return 'Elimina Foto';
      case AppLanguage.chinese:
        return '删除照片';
      case AppLanguage.japanese:
        return '写真を削除';
      default:
        return 'Eliminar foto';
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
      case AppLanguage.chinese:
        return '关闭';
      case AppLanguage.japanese:
        return '閉じる';
      default:
        return 'Cerrar';
    }
  }

  String get escanear {
    switch (language) {
      case AppLanguage.english:
        return 'Scan';
      case AppLanguage.portuguese:
        return 'Escanear';
      case AppLanguage.italian:
        return 'Scansiona';
      case AppLanguage.chinese:
        return '扫描';
      case AppLanguage.japanese:
        return 'スキャン';
      default:
        return 'Escanear';
    }
  }

  // === PERFIL: Títulos y Etiquetas ===

  String get informacionPersonal {
    switch (language) {
      case AppLanguage.english:
        return 'Personal Information';
      case AppLanguage.portuguese:
        return 'Informação Pessoal';
      case AppLanguage.italian:
        return 'Informazioni Personali';
      case AppLanguage.chinese:
        return '个人信息';
      case AppLanguage.japanese:
        return '個人情報';
      default:
        return 'Información Personal';
    }
  }

  String get nombreCompleto {
    switch (language) {
      case AppLanguage.english:
        return 'Full Name';
      case AppLanguage.portuguese:
        return 'Nome Completo';
      case AppLanguage.italian:
        return 'Nome Completo';
      case AppLanguage.chinese:
        return '全名';
      case AppLanguage.japanese:
        return 'フルネーム';
      default:
        return 'Nombre completo';
    }
  }

  String get correoElectronico {
    switch (language) {
      case AppLanguage.english:
        return 'Email';
      case AppLanguage.portuguese:
        return 'E-mail';
      case AppLanguage.italian:
        return 'Email';
      case AppLanguage.chinese:
        return '电子邮件';
      case AppLanguage.japanese:
        return 'メール';
      default:
        return 'Correo electrónico';
    }
  }

  String get telefono {
    switch (language) {
      case AppLanguage.english:
        return 'Phone';
      case AppLanguage.portuguese:
        return 'Telefone';
      case AppLanguage.italian:
        return 'Telefono';
      case AppLanguage.chinese:
        return '电话';
      case AppLanguage.japanese:
        return '電話';
      default:
        return 'Teléfono';
    }
  }

  String get conectarConAmigos {
    switch (language) {
      case AppLanguage.english:
        return 'Connect with Friends';
      case AppLanguage.portuguese:
        return 'Conectar com Amigos';
      case AppLanguage.italian:
        return 'Connetti con Amici';
      case AppLanguage.chinese:
        return '与朋友联系';
      case AppLanguage.japanese:
        return '友達とつながる';
      default:
        return 'Conectar con amigos';
    }
  }

  String get misAmigos {
    switch (language) {
      case AppLanguage.english:
        return 'My Friends';
      case AppLanguage.portuguese:
        return 'Meus Amigos';
      case AppLanguage.italian:
        return 'I Miei Amici';
      case AppLanguage.chinese:
        return '我的朋友';
      case AppLanguage.japanese:
        return 'マイフレンド';
      default:
        return 'Mis amigos';
    }
  }

  String get miCodigoQR {
    switch (language) {
      case AppLanguage.english:
        return 'My QR Code';
      case AppLanguage.portuguese:
        return 'Meu Código QR';
      case AppLanguage.italian:
        return 'Il Mio Codice QR';
      case AppLanguage.chinese:
        return '我的二维码';
      case AppLanguage.japanese:
        return 'マイQRコード';
      default:
        return 'Mi código QR';
    }
  }

  String get escanearCodigoQR {
    switch (language) {
      case AppLanguage.english:
        return 'Scan QR Code';
      case AppLanguage.portuguese:
        return 'Escanear Código QR';
      case AppLanguage.italian:
        return 'Scansiona Codice QR';
      case AppLanguage.chinese:
        return '扫描二维码';
      case AppLanguage.japanese:
        return 'QRコードをスキャン';
      default:
        return 'Escanear código QR';
    }
  }

  String get estadoSuscripcion {
    switch (language) {
      case AppLanguage.english:
        return 'Subscription Status';
      case AppLanguage.portuguese:
        return 'Estado da Assinatura';
      case AppLanguage.italian:
        return 'Stato Abbonamento';
      case AppLanguage.chinese:
        return '订阅状态';
      case AppLanguage.japanese:
        return 'サブスクリプションの状態';
      default:
        return 'Estado de suscripción';
    }
  }

  String get estadisticasCuenta {
    switch (language) {
      case AppLanguage.english:
        return 'Account Statistics';
      case AppLanguage.portuguese:
        return 'Estatísticas da Conta';
      case AppLanguage.italian:
        return 'Statistiche Account';
      case AppLanguage.chinese:
        return '账户统计';
      case AppLanguage.japanese:
        return 'アカウント統計';
      default:
        return 'Estadísticas de la cuenta';
    }
  }

  String get estado {
    switch (language) {
      case AppLanguage.english:
        return 'Status';
      case AppLanguage.portuguese:
        return 'Estado';
      case AppLanguage.italian:
        return 'Stato';
      case AppLanguage.chinese:
        return '状态';
      case AppLanguage.japanese:
        return 'ステータス';
      default:
        return 'Estado';
    }
  }

  String get plan {
    switch (language) {
      case AppLanguage.english:
        return 'Plan';
      case AppLanguage.portuguese:
        return 'Plano';
      case AppLanguage.italian:
        return 'Piano';
      case AppLanguage.chinese:
        return '计划';
      case AppLanguage.japanese:
        return 'プラン';
      default:
        return 'Plan';
    }
  }

  String get tiempoRestante {
    switch (language) {
      case AppLanguage.english:
        return 'Remaining Time';
      case AppLanguage.portuguese:
        return 'Tempo Restante';
      case AppLanguage.italian:
        return 'Tempo Rimanente';
      case AppLanguage.chinese:
        return '剩余时间';
      case AppLanguage.japanese:
        return '残り時間';
      default:
        return 'Tiempo restante';
    }
  }

  String get miembroDesde {
    switch (language) {
      case AppLanguage.english:
        return 'Member Since';
      case AppLanguage.portuguese:
        return 'Membro Desde';
      case AppLanguage.italian:
        return 'Membro Dal';
      case AppLanguage.chinese:
        return '会员自';
      case AppLanguage.japanese:
        return 'メンバー登録日';
      default:
        return 'Miembro desde';
    }
  }

  String get transaccionesCreadas {
    switch (language) {
      case AppLanguage.english:
        return 'Transactions Created';
      case AppLanguage.portuguese:
        return 'Transações Criadas';
      case AppLanguage.italian:
        return 'Transazioni Create';
      case AppLanguage.chinese:
        return '创建的交易';
      case AppLanguage.japanese:
        return '作成された取引';
      default:
        return 'Transacciones creadas';
    }
  }

  String get eventosCompartidosCount {
    switch (language) {
      case AppLanguage.english:
        return 'Shared Events';
      case AppLanguage.portuguese:
        return 'Eventos Compartilhados';
      case AppLanguage.italian:
        return 'Eventi Condivisi';
      case AppLanguage.chinese:
        return '共享活动';
      case AppLanguage.japanese:
        return '共有イベント';
      default:
        return 'Eventos compartidos';
    }
  }

  String get ahorrosTotales {
    switch (language) {
      case AppLanguage.english:
        return 'Total Savings';
      case AppLanguage.portuguese:
        return 'Economias Totais';
      case AppLanguage.italian:
        return 'Risparmi Totali';
      case AppLanguage.chinese:
        return '总储蓄';
      case AppLanguage.japanese:
        return '総貯蓄額';
      default:
        return 'Ahorros totales';
    }
  }

  String get agregado {
    switch (language) {
      case AppLanguage.english:
        return 'Added';
      case AppLanguage.portuguese:
        return 'Adicionado';
      case AppLanguage.italian:
        return 'Aggiunto';
      case AppLanguage.chinese:
        return '已添加';
      case AppLanguage.japanese:
        return '追加済み';
      default:
        return 'Agregado';
    }
  }

  // === PERFIL: Mensajes ===

  String get perfilActualizadoExito {
    switch (language) {
      case AppLanguage.english:
        return '✅ Profile updated successfully';
      case AppLanguage.portuguese:
        return '✅ Perfil atualizado com sucesso';
      case AppLanguage.italian:
        return '✅ Profilo aggiornato con successo';
      case AppLanguage.chinese:
        return '✅ 个人资料更新成功';
      case AppLanguage.japanese:
        return '✅ プロフィールが正常に更新されました';
      default:
        return '✅ Perfil actualizado correctamente';
    }
  }

  String get fotoPerfilActualizada {
    switch (language) {
      case AppLanguage.english:
        return '✅ Profile photo updated';
      case AppLanguage.portuguese:
        return '✅ Foto de perfil atualizada';
      case AppLanguage.italian:
        return '✅ Foto profilo aggiornata';
      case AppLanguage.chinese:
        return '✅ 个人照片已更新';
      case AppLanguage.japanese:
        return '✅ プロフィール写真が更新されました';
      default:
        return '✅ Foto de perfil actualizada';
    }
  }

  String get fotoPerfilEliminada {
    switch (language) {
      case AppLanguage.english:
        return 'Profile photo deleted';
      case AppLanguage.portuguese:
        return 'Foto de perfil excluída';
      case AppLanguage.italian:
        return 'Foto profilo eliminata';
      case AppLanguage.chinese:
        return '个人照片已删除';
      case AppLanguage.japanese:
        return 'プロフィール写真が削除されました';
      default:
        return 'Foto de perfil eliminada';
    }
  }

  String get camaraNoDisponibleWindows {
    switch (language) {
      case AppLanguage.english:
        return 'Camera is not available on Windows.\nSelect an image from your gallery.';
      case AppLanguage.portuguese:
        return 'Câmera não disponível no Windows.\nSelecione uma imagem da galeria.';
      case AppLanguage.italian:
        return 'Fotocamera non disponibile su Windows.\nSeleziona un\'immagine dalla galleria.';
      case AppLanguage.chinese:
        return 'Windows上无法使用相机。\n请从图库中选择图片。';
      case AppLanguage.japanese:
        return 'Windowsではカメラが使用できません。\nギャラリーから画像を選択してください。';
      default:
        return 'La cámara no está disponible en Windows.\nSelecciona una imagen de tu galería.';
    }
  }

  String get compartirCodigoQR {
    switch (language) {
      case AppLanguage.english:
        return 'Share this code so others can add you';
      case AppLanguage.portuguese:
        return 'Compartilhe este código para que outros possam te adicionar';
      case AppLanguage.italian:
        return 'Condividi questo codice per essere aggiunto';
      case AppLanguage.chinese:
        return '分享此代码以便其他人添加您';
      case AppLanguage.japanese:
        return '他の人があなたを追加できるようにこのコードを共有してください';
      default:
        return 'Comparte este código para que otros te agreguen';
    }
  }

  String get escanerQRNoDisponibleWindows {
    switch (language) {
      case AppLanguage.english:
        return 'QR scanner is not available on Windows. Use the mobile version.';
      case AppLanguage.portuguese:
        return 'Escâner QR não disponível no Windows. Use a versão móvel.';
      case AppLanguage.italian:
        return 'Scanner QR non disponibile su Windows. Usa la versione mobile.';
      case AppLanguage.chinese:
        return 'Windows上无法使用二维码扫描仪。请使用移动版本。';
      case AppLanguage.japanese:
        return 'WindowsではQRスキャナーが使用できません。モバイル版を使用してください。';
      default:
        return 'El escáner de QR no está disponible en Windows. Usa la versión móvil.';
    }
  }

  String get noPuedesAgregarteATiMismo {
    switch (language) {
      case AppLanguage.english:
        return '❌ You cannot add yourself';
      case AppLanguage.portuguese:
        return '❌ Você não pode adicionar a si mesmo';
      case AppLanguage.italian:
        return '❌ Non puoi aggiungere te stesso';
      case AppLanguage.chinese:
        return '❌ 您不能添加自己';
      case AppLanguage.japanese:
        return '❌ 自分自身を追加することはできません';
      default:
        return '❌ No puedes agregarte a ti mismo';
    }
  }

  String get usuarioYaEnListaAmigos {
    switch (language) {
      case AppLanguage.english:
        return 'This user is already in your friends list';
      case AppLanguage.portuguese:
        return 'Este usuário já está na sua lista de amigos';
      case AppLanguage.italian:
        return 'Questo utente è già nella tua lista amici';
      case AppLanguage.chinese:
        return '该用户已在您的好友列表中';
      case AppLanguage.japanese:
        return 'このユーザーは既に友達リストに登録されています';
      default:
        return 'Este usuario ya está en tu lista de amigos';
    }
  }

  String amigoAgregadoExito(String nombre) {
    switch (language) {
      case AppLanguage.english:
        return '✅ $nombre added to your friends';
      case AppLanguage.portuguese:
        return '✅ $nombre adicionado aos seus amigos';
      case AppLanguage.italian:
        return '✅ $nombre aggiunto ai tuoi amici';
      case AppLanguage.chinese:
        return '✅ $nombre 已添加到您的好友';
      case AppLanguage.japanese:
        return '✅ $nombre が友達に追加されました';
      default:
        return '✅ $nombre agregado a tus amigos';
    }
  }

  String get codigoQRInvalido {
    switch (language) {
      case AppLanguage.english:
        return '❌ Invalid QR code';
      case AppLanguage.portuguese:
        return '❌ Código QR inválido';
      case AppLanguage.italian:
        return '❌ Codice QR non valido';
      case AppLanguage.chinese:
        return '❌ 无效的二维码';
      case AppLanguage.japanese:
        return '❌ 無効なQRコード';
      default:
        return '❌ Código QR inválido';
    }
  }

  String get eliminarAmigoTitulo {
    switch (language) {
      case AppLanguage.english:
        return 'Remove Friend';
      case AppLanguage.portuguese:
        return 'Remover Amigo';
      case AppLanguage.italian:
        return 'Rimuovi Amico';
      case AppLanguage.chinese:
        return '删除好友';
      case AppLanguage.japanese:
        return '友達を削除';
      default:
        return 'Eliminar amigo';
    }
  }

  String eliminarAmigoConfirmacion(String nombre) {
    switch (language) {
      case AppLanguage.english:
        return 'Do you want to remove $nombre from your friends?';
      case AppLanguage.portuguese:
        return 'Deseja remover $nombre de seus amigos?';
      case AppLanguage.italian:
        return 'Vuoi rimuovere $nombre dai tuoi amici?';
      case AppLanguage.chinese:
        return '您要从好友中删除 $nombre 吗？';
      case AppLanguage.japanese:
        return '$nombre を友達から削除しますか？';
      default:
        return '¿Deseas eliminar a $nombre de tus amigos?';
    }
  }

  String get amigoEliminado {
    switch (language) {
      case AppLanguage.english:
        return 'Friend removed';
      case AppLanguage.portuguese:
        return 'Amigo removido';
      case AppLanguage.italian:
        return 'Amico rimosso';
      case AppLanguage.chinese:
        return '已删除好友';
      case AppLanguage.japanese:
        return '友達が削除されました';
      default:
        return 'Amigo eliminado';
    }
  }

  String get noTienesAmigosAgregados {
    switch (language) {
      case AppLanguage.english:
        return 'You have no friends added';
      case AppLanguage.portuguese:
        return 'Você não tem amigos adicionados';
      case AppLanguage.italian:
        return 'Non hai amici aggiunti';
      case AppLanguage.chinese:
        return '您没有添加好友';
      case AppLanguage.japanese:
        return '友達が追加されていません';
      default:
        return 'No tienes amigos agregados';
    }
  }

  String get escanearQRParaAgregar {
    switch (language) {
      case AppLanguage.english:
        return 'Scan a QR code to add';
      case AppLanguage.portuguese:
        return 'Escaneie um código QR para adicionar';
      case AppLanguage.italian:
        return 'Scansiona un codice QR per aggiungere';
      case AppLanguage.chinese:
        return '扫描二维码添加';
      case AppLanguage.japanese:
        return 'QRコードをスキャンして追加';
      default:
        return 'Escanea un código QR para agregar';
    }
  }

  String get colocarQREnMarco {
    switch (language) {
      case AppLanguage.english:
        return 'Place the QR code in the frame';
      case AppLanguage.portuguese:
        return 'Coloque o código QR no quadro';
      case AppLanguage.italian:
        return 'Posiziona il codice QR nella cornice';
      case AppLanguage.chinese:
        return '将二维码放在框架中';
      case AppLanguage.japanese:
        return 'QRコードをフレームに配置してください';
      default:
        return 'Coloca el código QR en el marco';
    }
  }

  String errorSeleccionarImagen(String error) {
    switch (language) {
      case AppLanguage.english:
        return 'Error selecting image: $error';
      case AppLanguage.portuguese:
        return 'Erro ao selecionar imagem: $error';
      case AppLanguage.italian:
        return 'Errore nella selezione dell\'immagine: $error';
      case AppLanguage.chinese:
        return '选择图片时出错：$error';
      case AppLanguage.japanese:
        return '画像の選択エラー：$error';
      default:
        return 'Error al seleccionar imagen: $error';
    }
  }

  // === PERFIL: Estados y Valores ===

  String get usuario {
    switch (language) {
      case AppLanguage.english:
        return 'User';
      case AppLanguage.portuguese:
        return 'Usuário';
      case AppLanguage.italian:
        return 'Utente';
      case AppLanguage.chinese:
        return '用户';
      case AppLanguage.japanese:
        return 'ユーザー';
      default:
        return 'Usuario';
    }
  }

  String get premiumEstrella {
    switch (language) {
      case AppLanguage.english:
        return 'Premium ⭐';
      case AppLanguage.portuguese:
        return 'Premium ⭐';
      case AppLanguage.italian:
        return 'Premium ⭐';
      case AppLanguage.chinese:
        return 'Premium ⭐';
      case AppLanguage.japanese:
        return 'Premium ⭐';
      default:
        return 'Premium ⭐';
    }
  }

  String get gratuito {
    switch (language) {
      case AppLanguage.english:
        return 'Free';
      case AppLanguage.portuguese:
        return 'Gratuito';
      case AppLanguage.italian:
        return 'Gratuito';
      case AppLanguage.chinese:
        return '免费';
      case AppLanguage.japanese:
        return '無料';
      default:
        return 'Gratuito';
    }
  }

  String get mensual {
    switch (language) {
      case AppLanguage.english:
        return 'Monthly';
      case AppLanguage.portuguese:
        return 'Mensal';
      case AppLanguage.italian:
        return 'Mensile';
      case AppLanguage.chinese:
        return '每月';
      case AppLanguage.japanese:
        return '月額';
      default:
        return 'Mensual';
    }
  }

  String get anual {
    switch (language) {
      case AppLanguage.english:
        return 'Annual';
      case AppLanguage.portuguese:
        return 'Anual';
      case AppLanguage.italian:
        return 'Annuale';
      case AppLanguage.chinese:
        return '每年';
      case AppLanguage.japanese:
        return '年額';
      default:
        return 'Anual';
    }
  }

  String get expirado {
    switch (language) {
      case AppLanguage.english:
        return 'Expired';
      case AppLanguage.portuguese:
        return 'Expirado';
      case AppLanguage.italian:
        return 'Scaduto';
      case AppLanguage.chinese:
        return '已过期';
      case AppLanguage.japanese:
        return '期限切れ';
      default:
        return 'Expirado';
    }
  }

  String get fechaDesconocida {
    switch (language) {
      case AppLanguage.english:
        return 'Unknown date';
      case AppLanguage.portuguese:
        return 'Data desconhecida';
      case AppLanguage.italian:
        return 'Data sconosciuta';
      case AppLanguage.chinese:
        return '未知日期';
      case AppLanguage.japanese:
        return '不明な日付';
      default:
        return 'Fecha desconocida';
    }
  }

  String get hoy {
    switch (language) {
      case AppLanguage.english:
        return 'Today';
      case AppLanguage.portuguese:
        return 'Hoje';
      case AppLanguage.italian:
        return 'Oggi';
      case AppLanguage.chinese:
        return '今天';
      case AppLanguage.japanese:
        return '今日';
      default:
        return 'Hoy';
    }
  }

  String get ayer {
    switch (language) {
      case AppLanguage.english:
        return 'Yesterday';
      case AppLanguage.portuguese:
        return 'Ontem';
      case AppLanguage.italian:
        return 'Ieri';
      case AppLanguage.chinese:
        return '昨天';
      case AppLanguage.japanese:
        return '昨日';
      default:
        return 'Ayer';
    }
  }

  // === PERFIL: Tiempo (singular/plural) ===

  String mes(int cantidad) {
    final esSingular = cantidad == 1;
    switch (language) {
      case AppLanguage.english:
        return esSingular ? 'month' : 'months';
      case AppLanguage.portuguese:
        return esSingular ? 'mês' : 'meses';
      case AppLanguage.italian:
        return esSingular ? 'mese' : 'mesi';
      case AppLanguage.chinese:
        return '个月';
      case AppLanguage.japanese:
        return 'ヶ月';
      default:
        return esSingular ? 'mes' : 'meses';
    }
  }

  String dia(int cantidad) {
    final esSingular = cantidad == 1;
    switch (language) {
      case AppLanguage.english:
        return esSingular ? 'day' : 'days';
      case AppLanguage.portuguese:
        return esSingular ? 'dia' : 'dias';
      case AppLanguage.italian:
        return esSingular ? 'giorno' : 'giorni';
      case AppLanguage.chinese:
        return '天';
      case AppLanguage.japanese:
        return '日';
      default:
        return esSingular ? 'día' : 'días';
    }
  }

  String hora(int cantidad) {
    final esSingular = cantidad == 1;
    switch (language) {
      case AppLanguage.english:
        return esSingular ? 'hour' : 'hours';
      case AppLanguage.portuguese:
        return esSingular ? 'hora' : 'horas';
      case AppLanguage.italian:
        return esSingular ? 'ora' : 'ore';
      case AppLanguage.chinese:
        return '小时';
      case AppLanguage.japanese:
        return '時間';
      default:
        return esSingular ? 'hora' : 'horas';
    }
  }

  String semana(int cantidad) {
    final esSingular = cantidad == 1;
    switch (language) {
      case AppLanguage.english:
        return esSingular ? 'week' : 'weeks';
      case AppLanguage.portuguese:
        return esSingular ? 'semana' : 'semanas';
      case AppLanguage.italian:
        return esSingular ? 'settimana' : 'settimane';
      case AppLanguage.chinese:
        return '周';
      case AppLanguage.japanese:
        return '週間';
      default:
        return esSingular ? 'semana' : 'semanas';
    }
  }

  String anio(int cantidad) {
    final esSingular = cantidad == 1;
    switch (language) {
      case AppLanguage.english:
        return esSingular ? 'year' : 'years';
      case AppLanguage.portuguese:
        return esSingular ? 'ano' : 'anos';
      case AppLanguage.italian:
        return esSingular ? 'anno' : 'anni';
      case AppLanguage.chinese:
        return '年';
      case AppLanguage.japanese:
        return '年';
      default:
        return esSingular ? 'año' : 'años';
    }
  }

  String haceDias(int dias) {
    switch (language) {
      case AppLanguage.english:
        return '$dias ${dia(dias)} ago';
      case AppLanguage.portuguese:
        return 'Há $dias ${dia(dias)}';
      case AppLanguage.italian:
        return '$dias ${dia(dias)} fa';
      case AppLanguage.chinese:
        return '$dias ${dia(dias)}前';
      case AppLanguage.japanese:
        return '$dias ${dia(dias)}前';
      default:
        return 'Hace $dias ${dia(dias)}';
    }
  }

  String haceSemanas(int semanas) {
    switch (language) {
      case AppLanguage.english:
        return '$semanas ${semana(semanas)} ago';
      case AppLanguage.portuguese:
        return 'Há $semanas ${semana(semanas)}';
      case AppLanguage.italian:
        return '$semanas ${semana(semanas)} fa';
      case AppLanguage.chinese:
        return '$semanas ${semana(semanas)}前';
      case AppLanguage.japanese:
        return '$semanas ${semana(semanas)}前';
      default:
        return 'Hace $semanas ${semana(semanas)}';
    }
  }

  String haceMeses(int meses) {
    switch (language) {
      case AppLanguage.english:
        return '$meses ${mes(meses)} ago';
      case AppLanguage.portuguese:
        return 'Há $meses ${mes(meses)}';
      case AppLanguage.italian:
        return '$meses ${mes(meses)} fa';
      case AppLanguage.chinese:
        return '$meses ${mes(meses)}前';
      case AppLanguage.japanese:
        return '$meses ${mes(meses)}前';
      default:
        return 'Hace $meses ${mes(meses)}';
    }
  }

  String haceAnios(int anios) {
    switch (language) {
      case AppLanguage.english:
        return '$anios ${anio(anios)} ago';
      case AppLanguage.portuguese:
        return 'Há $anios ${anio(anios)}';
      case AppLanguage.italian:
        return '$anios ${anio(anios)} fa';
      case AppLanguage.chinese:
        return '$anios ${anio(anios)}前';
      case AppLanguage.japanese:
        return '$anios ${anio(anios)}前';
      default:
        return 'Hace $anios ${anio(anios)}';
    }
  }
}
