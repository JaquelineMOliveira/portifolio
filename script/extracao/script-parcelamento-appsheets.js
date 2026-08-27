/* 
Script:
Função de geração de parcelas baseadas em forma de pagamento identificada como parcelado no AppSheets

Considera: 
-Data de vencimento como primeira data de vencimento da parcela,
-replica o número de linhas conforme sinalizado no campo de parcelas
-Novas linhas tem sua data de vencimento conforme respectivo mês 
-Cria campo de identificação de parcela ex. 1 de 12 A coluna Parcelas recebe o número atual da parcela gerada (2, 3, 4...)
-Atualiza a primeira linha original (Transformando na Parcela 1)
-Altera o ID incluindo o sufixo da parcela, mantendo a condição de Id único
-Como otimização, guarda na mémoria e só dispõe as parcelas na finalização do processo.
*/


function gerarParcelas() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("movimentacao"); // Nome da sua aba
   
  if (!sheet) {
    Logger.log("Aba 'movimentacao' não encontrada.");
    return;
  }

  var dataRange = sheet.getDataRange();
  var values = dataRange.getValues();
  
  if (values.length <= 1) return; 
  
  var headers = values[0];
  

  var colId = headers.indexOf("IdMovimentacao");
  var colFormaPgto = headers.indexOf("FormaPagamento");
  var colVencimento = headers.indexOf("DataVencimento");
  var colParcelas = headers.indexOf("Parcelas");
  var colValor = headers.indexOf("Valor");
  var colParcelamento = headers.indexOf("Parcelamento");
  

  if (colId === -1 || colVencimento === -1 || colParcelas === -1 || colParcelamento === -1) {
    Logger.log("Uma ou mais colunas não foram encontradas.");
    return;
  }
  
  var rowsToAppend = [];
  

  for (var r = 1; r < values.length; r++) {
    var row = values[r];
    var numParcelas = parseInt(row[colParcelas], 10);
    var parcelamentoInfo = row[colParcelamento];
    var originalId = row[colId];
    
   
    if (numParcelas > 1 && (!parcelamentoInfo || parcelamentoInfo === "")) {
      
      var dataVencimentoOriginal = new Date(row[colVencimento]);
      
      sheet.getRange(r + 1, colId + 1).setValue(originalId + "-1");
      sheet.getRange(r + 1, colParcelamento + 1).setValue("1/" + numParcelas);
      sheet.getRange(r + 1, colParcelas + 1).setValue(1); /
    
      for (var i = 2; i <= numParcelas; i++) {
        var newRow = row.slice(); 
        
  
        newRow[colId] = originalId + "-" + i;
        
       
        var newDate = new Date(dataVencimentoOriginal.getTime());
        newDate.setMonth(newDate.getMonth() + (i - 1));
        newRow[colVencimento] = newDate;
        
     
        newRow[colParcelamento] = i + "/" + numParcelas;
        
      
        newRow[colParcelas] = i; 
        
        rowsToAppend.push(newRow); 
      }
    }
  }
  

  if (rowsToAppend.length > 0) {
    sheet.getRange(sheet.getLastRow() + 1, 1, rowsToAppend.length, headers.length).setValues(rowsToAppend);
  }
}
