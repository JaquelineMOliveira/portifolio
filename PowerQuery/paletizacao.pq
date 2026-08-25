let
    Fonte = Sql.Database("servidor", "banco", [Query=sql),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"ENTREGA", type date}, {"EMISSAO", type date}, {"VALOR_VENDIDO", Currency.Type}, {"SUPERIOR", type number}, {"REPRESENTANTE", Int64.Type}, {"QUANTIDADE_VENDIDO", Int64.Type}, {"RAMO", Int64.Type}, {"REGIAO", Int64.Type}, {"CLIENTE", Int64.Type}, {"LOJA", Int64.Type}}),
    #"Colunas Reordenadas" = Table.ReorderColumns(#"Tipo Alterado",{"FILIAL", "PEDIDO", "ENTREGA", "EMISSAO", "FAMILIA", "FAMILIA_DS", "GRUPO", "GRUPO_DS", "PRODUTO", "PRODUTO_DS", "GRUPO_CLIENTE", "GRUPO_CLIENTE_NOME", "CLIENTE", "LOJA", "CLIENTE_NOME", "MUNICIPIO", "ESTADO", "REGIAO", "REGIAO_DS", "RAMO", "RAMO_DS", "REPRESENTANTE", "REPRESENTANTE_NOME", "SUPERIOR", "SUPERIOR_NOME", "QUANTIDADE_VENDIDO", "VALOR_VENDIDO", "PESO_VENDIDO", "BLOQUEIO_ANTECIPACAO", "TPPED"}),
    #"Tipo Alterado1" = Table.TransformColumnTypes(#"Colunas Reordenadas",{{"GRUPO_CLIENTE", Int64.Type}, {"PRODUTO", Int64.Type}, {"GRUPO", Int64.Type}, {"FAMILIA", Int64.Type}}),
    #"Idade Inserida" = Table.AddColumn(#"Tipo Alterado1", "Idade", each Date.From(DateTime.LocalNow()) - [EMISSAO], type duration),
    #"Tipo Alterado2" = Table.TransformColumnTypes(#"Idade Inserida",{{"Idade", Int64.Type}}),
    #"Linhas Classificadas" = Table.Sort(#"Tipo Alterado2",{{"Idade", Order.Descending}}),
    #"Idade Inserida1" = Table.AddColumn(#"Linhas Classificadas", "Idade.1", each Date.From(DateTime.LocalNow()) - [ENTREGA], type duration),
    #"Tipo Alterado3" = Table.TransformColumnTypes(#"Idade Inserida1",{{"Idade.1", Int64.Type}}),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Tipo Alterado3",{{"Idade.1", "ENTREGA EM"}, {"Idade", "EMISSÃO HÁ"}}),
    #"Tipo Alterado4" = Table.TransformColumnTypes(#"Colunas Renomeadas",{{"PRODUTO", Int64.Type}}),
    #"Consultas Mescladas" = Table.NestedJoin(#"Tipo Alterado4", {"PRODUTO"}, QUADRO_GERAL_ESTOQUE, {"COD_PRODUTO"}, "QUADRO_GERAL_ESTOQUE", JoinKind.LeftOuter),
    #"QUADRO_GERAL_ESTOQUE Expandido" = Table.ExpandTableColumn(#"Consultas Mescladas", "QUADRO_GERAL_ESTOQUE", {"PALETE", "TOTAL"}, {"QUADRO_GERAL_ESTOQUE.PALETE", "QUADRO_GERAL_ESTOQUE.TOTAL"}),
    #"Colunas Renomeadas1" = Table.RenameColumns(#"QUADRO_GERAL_ESTOQUE Expandido",{{"QUADRO_GERAL_ESTOQUE.PALETE", "PALETE"}, {"QUADRO_GERAL_ESTOQUE.TOTAL", "ESTOQUE"}}),
    #"Consultas Mescladas1" = Table.NestedJoin(#"Colunas Renomeadas1", {"MUNICIPIO"}, KM, {"CIDADE"}, "KM", JoinKind.LeftOuter),
    #"KM Expandido" = Table.ExpandTableColumn(#"Consultas Mescladas1", "KM", {"DISTÂNCIA 1 VCA", "DISTÂNCIA 2 FS"}, {"KM.DISTÂNCIA 1 VCA", "KM.DISTÂNCIA 2 FS"}),
    #"Valor Substituído" = Table.ReplaceValue(#"KM Expandido",null,0,Replacer.ReplaceValue,{"ESTOQUE"}),
    #"Coluna Condicional Adicionada" = Table.AddColumn(#"Valor Substituído", "SALDO", each if [ESTOQUE] > 0 then "COM SALDO" else "SEM SALDO"),
    #"Coluna Condicional Adicionada1" = Table.AddColumn(#"Coluna Condicional Adicionada", "AGENDAMENTO", each if [RAMO_DS] = "CASH" then "AGENDAMENTO OBRIGATÓRIO" else if [REGIAO_DS] = "DISTRIBUIDOR" then "AGENDAMENTO OBRIGATÓRIO" else "SEM AGENDAMENTO"),
    #"Coluna Mesclada Inserida" = Table.AddColumn(#"Coluna Condicional Adicionada1", "RCA", each Text.Combine({Text.From([REPRESENTANTE], "pt-BR"), [REPRESENTANTE_NOME]}, " "), type text),
    #"Coluna Condicional Adicionada2" = Table.AddColumn(#"Coluna Mesclada Inserida", "PRE ANALISE DE STATUS", each if [PRE_CARGA] <> "      " then "Faturável" else if [SALDO] = "SEM SALDO" then "Aguardando Produção" else if [ENTREGA EM] > 5 then "Data Futura" else if [FRETE] = "FOB" then "Cliente Vai Retirar" else if [AGENDAMENTO] = "AGENDAMENTO OBRIGATÓRIO" then "Agendado" else "Aguardando Comercial"),
    #"Coluna Condicional Adicionada3" = Table.AddColumn(#"Coluna Condicional Adicionada2", "DIAS DE ENTREGA", each if [ENTREGA EM] > 5 then "Após 5 Dias" else if [ENTREGA EM] = 0 then "Hoje" else if [ENTREGA EM] >= 1 then "Próximos 5 Dias" else "Últimos Dias"),
    #"Valor Substituído1" = Table.ReplaceValue(#"Coluna Condicional Adicionada3",null,0,Replacer.ReplaceValue,{"KM.DISTÂNCIA 1 VCA", "KM.DISTÂNCIA 2 FS"}),
    #"Coluna Condicional Adicionada4" = Table.AddColumn(#"Valor Substituído1", "ORIGEM INDICADA", each if [KM.DISTÂNCIA 2 FS] < [KM.DISTÂNCIA 1 VCA] then "Filial" else if [KM.DISTÂNCIA 2 FS] > [KM.DISTÂNCIA 1 VCA] then "Matriz" else "S/ Dados"),
    #"Linhas Agrupadas" = Table.Group(#"Coluna Condicional Adicionada4", {"RCA", "PRODUTO", "PRODUTO_DS"}, {{"Qnt", each List.Sum([QUANTIDADE_VENDIDO]), type nullable number}, {"Paletes", each List.Max([PALETE]), type nullable number}, {"Peso", each List.Sum([PESO_VENDIDO]), type number}, {"KM MATRIZ", each List.Max([KM.DISTÂNCIA 1 VCA]), type nullable number}, {"KM FILIAL", each List.Max([KM.DISTÂNCIA 2 FS]), type nullable number}, {"Valor", each List.Sum([VALOR_VENDIDO]), type nullable number}}),
    #"Coluna Condicional Adicionada6" = Table.AddColumn(#"Linhas Agrupadas", "PALETE", each if [PRODUTO] = 1050040003 then 84 else if [PRODUTO] = 2000300001 then 192 else if [PRODUTO] = 2000700001 then 104 else if [PRODUTO] = 2001000006 then 60 else if [PRODUTO] = 2000500001 then 80 else if [PRODUTO] = 2000000004 then 225 else if [PRODUTO] = 2000000001 then 225 else if [PRODUTO] = 2000000002 then 225 else if [PRODUTO] = 2000000003 then 225 else if [PRODUTO] = 2001000010 then 60 else if [PRODUTO] = 2001000009 then 60 else if [PRODUTO] = 2001000007 then 60 else if [PRODUTO] = 2001000008 then 60 else if [PRODUTO] = 1091000001 then 40 else [Paletes]),
    #"Personalização Adicionada" = Table.AddColumn(#"Coluna Condicional Adicionada6", "Paletização", each [Qnt]/[PALETE]),
    #"Linhas Agrupadas1" = Table.Group(#"Personalização Adicionada", {"RCA"}, {{"PESO", each List.Sum([Peso]), type number}, {"QNT", each List.Sum([Qnt]), type nullable number}, {"VALOR", each List.Sum([Valor]), type nullable number}, {"PALETIZAÇÃO", each List.Sum([Paletização]), type number}, {"KM DISTANCIA - MATRIZ", each List.Max([KM MATRIZ]), type nullable number}, {"KM DISTANCIA - FILIAL", each List.Max([KM FILIAL]), type nullable number}}),
    #"Coluna Condicional Adicionada5" = Table.AddColumn(#"Linhas Agrupadas1", "SAÍDA IDEAL", each if [#"KM DISTANCIA - MATRIZ"] > [#"KM DISTANCIA - FILIAL"] then "FILIAL" else if [#"KM DISTANCIA - MATRIZ"] = [#"KM DISTANCIA - FILIAL"] then "Sem dados" else "MATRIZ"),
    #"Coluna Condicional Adicionada7" = Table.AddColumn(#"Coluna Condicional Adicionada5", "KM INDICADO", each if [#"KM DISTANCIA - MATRIZ"] > [#"KM DISTANCIA - FILIAL"] then [#"KM DISTANCIA - FILIAL"] else [#"KM DISTANCIA - MATRIZ"]),
    #"Personalização Adicionada1" = Table.AddColumn(#"Coluna Condicional Adicionada7", "Nº VEICULOS", each if [PALETIZAÇÃO] >= 30 then [PALETIZAÇÃO]/30
else if [PALETIZAÇÃO] = null then 0
else if [PALETIZAÇÃO] < 1 then 0
else if [PALETIZAÇÃO] >= 1 then 1
else 0),
    #"Tipo Alterado5" = Table.TransformColumnTypes(#"Personalização Adicionada1",{{"Nº VEICULOS", Int64.Type}}),
    #"Personalização Adicionada2" = Table.AddColumn(#"Tipo Alterado5", "VEICULO", each if [PESO] < 9000 and [KM INDICADO] <= 300
    then "Falta Compl/ TOCO"
else if [PESO] >= 9000 and [PALETIZAÇÃO] <= 12 and [KM INDICADO] <= 300
    then "TOCO"
else if [PESO] < 14000 and [KM INDICADO] > 300
    then "Falta Compl/ TRUCK"
else if [PESO] >= 9000 and [PALETIZAÇÃO] <= 12 and [KM INDICADO] > 300
    then "Falta Compl/ TRUCK"
else if [PESO] >= 14000 and [PALETIZAÇÃO] <= 16
    then "TRUCK"
else if [PESO] >= 170000 and [PALETIZAÇÃO] <= 20
    then "BITRUCK"
else if [PESO] <= 30000 and [PALETIZAÇÃO] <= 30
    then "CARRETA"
else if [PESO] > 30000 and [PALETIZAÇÃO] > 30
    then "CARRETA"
else
    "CARRETA"),
    #"Tipo Alterado6" = Table.TransformColumnTypes(#"Personalização Adicionada2",{{"PALETIZAÇÃO", type number}}),
    Arredondado = Table.TransformColumns(#"Tipo Alterado6",{{"PALETIZAÇÃO", each Number.Round(_, 2), type number}}),
    #"Colunas Renomeadas2" = Table.RenameColumns(Arredondado,{{"KM DISTANCIA - MATRIZ", "KM MATRIZ"}, {"KM DISTANCIA - FILIAL", "KM FILIAL"}})
in
    #"Colunas Renomeadas2"
