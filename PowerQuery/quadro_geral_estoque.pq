let
    Fonte = Sql.Database("servidor", "banco", [Query="sql]),
    #"Coluna Duplicada" = Table.DuplicateColumn(Fonte, "B2_QATU", "B2_QATU - Copiar"),
    #"Coluna em pivô" = Table.Pivot(#"Coluna Duplicada", List.Distinct(#"Coluna Duplicada"[B2_FILIAL]), "B2_FILIAL", "B2_QATU - Copiar", List.Sum),
    #"Coluna em pivô1" = Table.Pivot(#"Coluna em pivô", List.Distinct(#"Coluna em pivô"[B2_LOCAL]), "B2_LOCAL", "B2_QATU", List.Sum),
    #"Linhas Agrupadas" = Table.Group(#"Coluna em pivô1", {"B1_COD", "B1_DESC", "B1_TIPO","FAMILIA","MARCA"}, {
        {"ETQ01", each List.Sum(try [010101] otherwise {}), type nullable number}, 
        {"ETQ02", each List.Sum(try [010102] otherwise {}), type nullable number}, 
        {"ETQ12", each List.Sum(try [12] otherwise {}), type nullable number}, 
        {"ETQ80", each List.Sum(try [80] otherwise {}), type nullable number}, 
        {"ETQ54", each List.Sum(try [54] otherwise {}), type nullable number}, 
        {"ETQ55", each List.Sum(try [55] otherwise {}), type nullable number},
        {"PESO", each List.Max([B1_PESBRU]), type number}, 
        {"PALETE", each List.Max([B1_TQPAL]), type number}
    }),
    #"Valor Substituído" = Table.ReplaceValue(#"Linhas Agrupadas",null,0,Replacer.ReplaceValue,{"ETQ01", "ETQ02", "ETQ12", "ETQ80", "ETQ54","ETQ55"}),
    
    #"Colunas Renomeadas" = Table.RenameColumns(#"Valor Substituído",{{"B1_DESC", "PRODUTO"}, {"B1_COD", "COD_PRODUTO"}, {"B1_TIPO", "TIPO"}}),
    
    #"Soma Inserida" = Table.AddColumn(#"Colunas Renomeadas", "Adição", each [ETQ54] + [ETQ80] + [ETQ12], Int64.Type),
    #"Colunas Renomeadas1" = Table.RenameColumns(#"Soma Inserida",{{"Adição", "TOTAL"}}),
    
    // ATENÇÃO: COD_PRODUTO mantido como Int64.Type
    #"Tipo Alterado1" = Table.TransformColumnTypes(#"Colunas Renomeadas1",{{"COD_PRODUTO", Int64.Type}}),
    
    #"Linhas Filtradas" = Table.SelectRows(#"Tipo Alterado1", each ([TIPO] = "ME" or [TIPO] = "PA")),
    
    // SALDO MATRIZ e SALDO FILIAL serão automaticamente do tipo Text devido aos valores de retorno "SEM SALDO" e "COM SALDO"
    #"Coluna Condicional Adicionada" = Table.AddColumn(#"Linhas Filtradas", "SALDO MATRIZ", each if [ETQ01] = 0 then "SEM SALDO" else "COM SALDO", Text.Type),
    #"Coluna Condicional Adicionada1" = Table.AddColumn(#"Coluna Condicional Adicionada", "SALDO FILIAL", each if [ETQ02] = 0 then "SEM SALDO" else "COM SALDO", Text.Type),
    #"Linhas Classificadas" = Table.Sort(#"Coluna Condicional Adicionada1",{{"COD_PRODUTO", Order.Ascending}}),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Linhas Classificadas",{{"SALDO MATRIZ", type text}, {"SALDO FILIAL", type text}, {"COD_PRODUTO", Int64.Type}})
in
    #"Tipo Alterado"
