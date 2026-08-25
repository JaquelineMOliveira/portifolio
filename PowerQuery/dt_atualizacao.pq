let
    Fonte = DateTimeZone.SwitchZone(DateTimeZone.LocalNow(), -3),
    Personalizar1 = #table(1, {{Fonte}}),
    Personalizar2 = Table.RenameColumns(Personalizar1,{{"Column1", "Data de atualização"}}),
    Personalizar3 = Table.TransformColumnTypes(#"Personalizar2",{{"Data de atualização", type datetimezone}})
in
    Personalizar3
