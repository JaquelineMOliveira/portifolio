/**
 * Script responsável por automatizar a extração de dados de arquivos PDF de contracheques 
 * armazenados em uma pasta do Google Drive, processando as informações textuais (com OCR) 
 * e estruturando os lançamentos (referência, pagamento, código, descrição, quantidade, 
 * valor e tipo) em uma planilha do Google Sheets. Também inclui a criação de um menu 
 * personalizado na interface da planilha.
 */

function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('⚙️ Extração')
    .addItem('Executar Extração Manual', 'extrairDadosContracheques')
    .addToUi();
}

function extrairDadosContracheques() {
  const folderId = 'id da pasta';
  const spreadsheetId = 'id do sheets';
  const targetGid = 1267675969; 
  
  const folder = DriveApp.getFolderById(folderId);
  const files = folder.searchFiles('mimeType = "application/pdf" and starred = false');
  const ss = SpreadsheetApp.openById(spreadsheetId);
  
  let sheet = ss.getSheets().find(s => s.getSheetId() == targetGid) || ss.getSheets()[0];

  if (sheet.getLastRow() === 0) {
    sheet.appendRow(['Mês e Ano Ref', 'Data Pagto', 'Décimo', 'Cód', 'Descrição', 'Qnt', 'Valor', 'Tipo']);
    sheet.getRange("1:1").setFontWeight("bold").setBackground("#d9d9d9");
  }

  while (files.hasNext()) {
    let file = files.next();
    try {
      let text = extrairTextoDePDFV3(file);
      
      let compMatch = text.match(/(\w+)\/(\d{4})/); 
      let mesTexto = compMatch ? compMatch[1] : "";
      let ano = parseInt(compMatch ? compMatch[2] : "0");
      let mesNum = converterMesParaNumero(mesTexto);
      
      let dataRef = "01/" + (mesNum < 10 ? "0" + mesNum : mesNum) + "/" + ano;

      let dataObjPagto = new Date(ano, mesNum, 1); 
      let dataPagto = Utilities.formatDate(dataObjPagto, Session.getScriptTimeZone(), "dd/MM/yyyy");

      let ehDecimo = (text.toUpperCase().includes("13º") || text.toUpperCase().includes("DECIMO")) ? "TRUE" : "FALSE";

      const regexItens = /(\d{3})\s+([A-Z\s.]{3,30})\s+([\d.]+)\s+([\d.,]+)/g;
      let match;
      let linhasParaInserir = [];

      while ((match = regexItens.exec(text)) !== null) {
        let cod = match[1];
        let desc = match[2].trim();
        let qnt = parseFloat(match[3].replace(',', '.'));
        
        let valorLimpo = match[4].replace('R$', '').replace(/\./g, '').replace(',', '.').trim();
        let valorNumerico = parseFloat(valorLimpo);
        
        let codInt = parseInt(cod);
        let tipo = (codInt >= 700) ? "BASE" : (codInt >= 400 ? "DESCONTO" : "REMUNERAÇÃO");

        linhasParaInserir.push([
          dataRef,    
          dataPagto,  
          ehDecimo, 
          cod, 
          desc, 
          qnt, 
          valorNumerico, 
          tipo
        ]);
      }

      if (linhasParaInserir.length > 0) {
        let lastRow = sheet.getLastRow() + 1;
        sheet.getRange(lastRow, 1, linhasParaInserir.length, 8).setValues(linhasParaInserir);
        
        sheet.getRange(lastRow, 7, linhasParaInserir.length, 1).setNumberFormat("#,##0.00");
        
        file.setStarred(true); 
      }
    } catch (err) {
      console.error("Erro no arquivo " + file.getName() + ": " + err.toString());
    }
  }
  SpreadsheetApp.getUi().alert("Extração concluída com sucesso!");
}

function extrairTextoDePDFV3(file) {
  let resource = { name: file.getName(), mimeType: MimeType.GOOGLE_DOCS };
  let docFile = Drive.Files.create(resource, file.getBlob(), { ocr: true, ocrLanguage: "pt" });
  let doc = DocumentApp.openById(docFile.id);
  let text = doc.getBody().getText();
  Drive.Files.remove(docFile.id);
  return text;
}

function converterMesParaNumero(mes) {
  const meses = { 'Janeiro':1, 'Fevereiro':2, 'Marco':3, 'Março':3, 'Abril':4, 'Maio':5, 'Junho':6, 'Julho':7, 'Agosto':8, 'Setembro':9, 'Outubro':10, 'Novembro':11, 'Dezembro':12 };
  let mesLimpo = mes.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  return meses[mes] || meses[mesLimpo] || 1;
}
