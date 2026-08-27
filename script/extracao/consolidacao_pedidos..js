/**
 * Script responsável por automatizar a importação, conversão e consolidação de 
 * arquivos em formato Excel (.xlsx) localizados em uma pasta do Google Drive. 
 * O processo identifica os cabeçalhos específicos de produtos, limpa e padroniza 
 * os dados de quantidade e preço de venda, agrega duplicatas e preenche a aba 
 * de destino configurada no Google Sheets.
 */

const FOLDER_ID = 'id_da_pasta';
const SHEET_NAME = 'Aba_entrada_informacoes';

function importarDados() {
  const ui = SpreadsheetApp.getUi();
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();

  try {
    const sheet = spreadsheet.getSheetByName(SHEET_NAME);

    if (!sheet) {
      ui.alert(`Erro: A planilha com o nome "${SHEET_NAME}" não foi encontrada.`);
      return;
    }

    const folder = DriveApp.getFolderById(FOLDER_ID);
    const files = folder.getFilesByType(MimeType.MICROSOFT_EXCEL);

    if (!files.hasNext()) {
      ui.alert('Nenhum arquivo .xlsx encontrado na pasta do Drive.');
      return;
    }

    const consolidatedData = {};
    let totalRowsProcessed = 0;

    while (files.hasNext()) {
      const file = files.next();

      const tempFile = Drive.Files.create(
        {
          name: file.getName(),
          mimeType: MimeType.GOOGLE_SHEETS
        },
        file.getBlob()
      );

      const tempSpreadsheet = SpreadsheetApp.openById(tempFile.id);
      const tempSheet = tempSpreadsheet.getSheets()[0];
      const data = tempSheet.getDataRange().getValues();

      if (data.length === 0) {
        DriveApp.getFileById(tempFile.id).setTrashed(true);
        continue;
      }

      let startRow = -1;
      for (let i = 0; i < data.length; i++) {
        const row = data[i];
        if (row[0] && String(row[0]).trim().toLowerCase() === 'produto') {
          startRow = i;
          break;
        }
      }

      if (startRow === -1) {
        ui.alert(`Aviso: O arquivo "${file.getName()}" não tem o cabeçalho 'Produto' e será ignorado.`);
        DriveApp.getFileById(tempFile.id).setTrashed(true);
        continue;
      }

      const headerRow = data[startRow].map(h => String(h).trim().toLowerCase());

      const idxProduto = headerRow.findIndex(h => h === 'produto');
      const idxQuantidade = headerRow.findIndex(h => h === 'qtde');
      const idxPrecoVenda = headerRow.findIndex(h => h === 'preço venda');

      if (idxProduto === -1 || idxQuantidade === -1 || idxPrecoVenda === -1) {
        ui.alert(`Aviso: O arquivo "${file.getName()}" não tem todos os cabeçalhos necessários.`);
        DriveApp.getFileById(tempFile.id).setTrashed(true);
        continue;
      }

      for (let i = startRow + 1; i < data.length; i++) {
        const row = data[i];

        if (!row[idxProduto] || String(row[idxProduto]).includes('Página')) break;

        const codigoDescricao = String(row[idxProduto]).trim();
        const { codigoProduto, descricaoProduto } = extrairCodigoEDescricao(codigoDescricao);

        const quantidade = limparQuantidade(row[idxQuantidade]);
        const precoVenda = limparNumero(row[idxPrecoVenda]);

        if (!codigoProduto || !descricaoProduto || isNaN(quantidade) || isNaN(precoVenda)) continue;

        const precoVendaKey = precoVenda.toFixed(2);
        const key = `${codigoProduto}|${descricaoProduto}|${precoVendaKey}`;

        if (consolidatedData[key]) {
          consolidatedData[key].quantidade += quantidade;
        } else {
          consolidatedData[key] = {
            codigo: codigoProduto,
            descricao: descricaoProduto,
            quantidade: quantidade,
            precoVenda: precoVenda
          };
        }

        totalRowsProcessed++;
      }

      DriveApp.getFileById(tempFile.id).setTrashed(true);
    }

    sheet.clear();

    sheet.appendRow([
      'CODIGO',
      'DESCICAO',
      'QUANTIDADE',
      'PRECO VENDA'
    ]);

    const finalData = Object.values(consolidatedData).map(item => [
      item.codigo,
      item.descricao,
      item.quantidade,
      item.precoVenda
    ]);

    if (finalData.length > 0) {
      sheet.getRange(2, 1, finalData.length, finalData[0].length)
           .setValues(finalData);
    }

    ui.alert(`Importação concluída!
${totalRowsProcessed} linhas processadas
${finalData.length} linhas consolidadas`);

  } catch (error) {
    ui.alert(`Erro: ${error.message}`);
  }
}

function extrairCodigoEDescricao(codigoDescricao) {
  const codigoProduto = codigoDescricao.split(' ')[0];
  let descricaoProduto = '';

  const separatorIndex = codigoDescricao.indexOf(' - ');
  if (separatorIndex !== -1) {
    descricaoProduto = codigoDescricao.substring(separatorIndex + 3).trim();
  } else {
    descricaoProduto = codigoDescricao.substring(codigoProduto.length).trim();
  }

  return { codigoProduto, descricaoProduto };
}

function limparNumero(valor) {
  if (!valor) return 0;
  const numString = String(valor)
    .replace('R$', '')
    .replace(/\./g, '')
    .replace(',', '.')
    .trim();

  const num = parseFloat(numString);
  return isNaN(num) ? 0 : num;
}

function limparQuantidade(valor) {
  if (!valor) return 0;

  let numString = String(valor);
  const lastCommaIndex = numString.lastIndexOf(',');

  if (lastCommaIndex !== -1) {
    numString = numString.substring(0, lastCommaIndex);
  }

  numString = numString.replace(/[\.,]/g, '').trim();
  const num = parseInt(numString, 10);

  return isNaN(num) ? 0 : num;
}

function importarPedidos() {
  Logger.log("OK");
}
