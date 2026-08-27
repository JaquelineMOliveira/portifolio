/* 
-------------------------------------------------------------
Titulo: dim_cliente
Descrição: dimensões de clientes ativos e inativos registrados na filial '0101', considera agrupamento, endereço, contatos e tipologia do cliente.
Feito em: 20 de maio de 2026 às 15h04 BRT 
Por: Jaqueline M. Oliveira 

Chave: ''id_cliente''
-------------------------------------------------------------
*/
SELECT

ISNULL(ACY.ACY_GRPVEN,'-') id_grupo
,ISNULL(TRIM(ACY.ACY_DESCRI),'-') desc_grupo
,CONCAT(ISNULL(ACY.ACY_GRPVEN,'-') , ' - ',ISNULL(TRIM(UPPER(ACY.ACY_DESCRI)),'-')) AS grupo

,CONCAT(SA1.A1_COD,SA1.A1_LOJA) AS id_cliente
,UPPER(TRIM(SA1.A1_NOME)) AS desc_cliente
,CONCAT(SA1.A1_COD,SA1.A1_LOJA,' - ',SA1.A1_NOME) AS cliente
,UPPER(TRIM(SA1.A1_TFANT)) 'nome_fantasia'
,CASE 
    WHEN SA1.A1_PESSOA = 'J' THEN
        SUBSTRING(DOC.NUM, 1, 2)  + '.' +
        SUBSTRING(DOC.NUM, 3, 3)  + '.' +
        SUBSTRING(DOC.NUM, 6, 3)  + '/' +
        SUBSTRING(DOC.NUM, 9, 4)  + '-' +
        SUBSTRING(DOC.NUM, 13, 2)
    WHEN SA1.A1_PESSOA = 'F' THEN
        SUBSTRING(DOC.NUM, 1, 3)  + '.' +
        SUBSTRING(DOC.NUM, 4, 3)  + '.' +
        SUBSTRING(DOC.NUM, 7, 3)  + '-' +
        SUBSTRING(DOC.NUM, 10, 2)
    ELSE 'N/C'
END cnpj
,TRIM(UPPER(SA1.A1_CONTATO)) AS Contato
,TRIM(SA1.A1_DDD) AS ddd
,CASE 
     WHEN LEN(REPLACE(SA1.A1_TEL, '-', '')) = 9 THEN 
        SUBSTRING(REPLACE(SA1.A1_TEL, '-', ''), 1, 1) + '.' + 
        SUBSTRING(REPLACE(SA1.A1_TEL, '-', ''), 2, 4) + '-' + 
        SUBSTRING(REPLACE(SA1.A1_TEL, '-', ''), 6, 4)

    WHEN LEN(REPLACE(SA1.A1_TEL, '-', '')) = 8 THEN 
        SUBSTRING(REPLACE(SA1.A1_TEL, '-', ''), 1, 4) + '-' + 
        SUBSTRING(REPLACE(SA1.A1_TEL, '-', ''), 5, 4)
    ELSE REPLACE(SA1.A1_TEL, '-', '') 
END AS telefone
,LOWER(TRIM(SA1.A1_EMAIL)) AS 'email'

,UPPER(TRIM(SA1.A1_TOBSCLI)) observacao
,UPPER(TRIM(SA1.A1_COMPENT)) complemento

,UPPER(TRIM(SA1.A1_END)) endereco
,UPPER(TRIM(SA1.A1_BAIRRO)) bairro
,UPPER(TRIM(SA1.A1_MUN)) municipio
,UPPER(TRIM(SA1.A1_EST)) uf
,   SUBSTRING(SA1.A1_CEP, 1, 2) + '.' + 
    SUBSTRING(SA1.A1_CEP, 3, 3) + '-' + 
    SUBSTRING(SA1.A1_CEP, 6, 3) cep
,TRIM(SA1.A1_COD_MUN) id_municipio

,ISNULL(SA1.A1_GRPTRIB,0) id_grupo_tributario

,SA1.A1_TCDRAMO AS id_canal
,SA1.A1_TTBPREC AS id_tabela_preco
,SA1.A1_TFORMPG AS forma_pagto
,SA1.A1_DTCAD AS dt_cadastro
,ISNULL(SA1.A1_PRICOM,'Sem Compra') AS dt_primeira_compra
,A1_VEND id_representante

,CASE SA1.A1_MSBLQL
        WHEN '1' THEN 'Bloqueado'
        WHEN '2' THEN 'Ativo'
        ELSE 'N/A'
    END AS bloqueio

            FROM SA1010 SA1 
                
         CROSS APPLY (
                        SELECT 
                        REPLACE(REPLACE(REPLACE(SA1.A1_CGC,'-',''),'.',''),'/','') AS NUM
                        ) DOC
        LEFT JOIN ACY010 ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN  AND  ACY.D_E_L_E_T_ <> '*' AND ACY.ACY_FILIAL = '0101'
        INNER JOIN ZZ6010 ZZ6 ON ZZ6.ZZ6_COD = SA1.A1_TCDRAMO AND ZZ6.D_E_L_E_T_ = ''
        LEFT JOIN SA3010 SA3 ON SA1.A1_VEND = SA3.A3_COD AND SA3.D_E_L_E_T_ = ''
        LEFT JOIN SA3010 SUP ON SUP.A3_COD = SA3.A3_SUPER AND SUP.D_E_L_E_T_ = ''

        WHERE 

        SA1.D_E_L_E_T_ <> '*'
