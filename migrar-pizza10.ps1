# ==============================================================================
# SCRIPT DE MIGRAÇÃO COMPLETA: SQL SERVER -> SUPABASE (PIZZA10)
# ==============================================================================
# Execução: powershell -NoProfile -ExecutionPolicy Bypass -File migrar-pizza10.ps1
# ==============================================================================

param(
    [string]$Server = ".\SQLEXPRESS22",
    [string]$Database = "DB_Locaki_Extraido",
    [string]$SupabaseUrl = "https://ykppjqamzrzgirewdgpa.supabase.co",
    [string]$SupabaseKey = "sb_publishable_iEBiMYqlR5tdMcdzS2MCww_sDtayvvE",
    [int]$BatchSize = 500,
    [switch]$ExportOnly = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Yellow
Write-Host "   PIZZA10 - MIGRAÇÃO DE DADOS (SQL SERVER -> SUPABASE)" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Servidor SQL: $Server" -ForegroundColor Cyan
Write-Host "Banco:        $Database" -ForegroundColor Cyan
Write-Host "Supabase URL: $SupabaseUrl" -ForegroundColor Cyan
Write-Host "Tamanho Lote: $BatchSize registros" -ForegroundColor Cyan
Write-Host ""

# Criar pasta para exportação local / backup
$dataDir = Join-Path $PSScriptRoot "data_export"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

$connStr = "Server=$Server;Database=$Database;Integrated Security=True;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)

function Send-SupabaseBatch {
    param(
        [string]$Table,
        [array]$Rows
    )
    if ($Rows.Count -eq 0) { return }

    $json = $Rows | ConvertTo-Json -Depth 5 -Compress
    $headers = @{
        "apikey"        = $SupabaseKey
        "Authorization" = "Bearer $SupabaseKey"
        "Content-Type"  = "application/json"
        "Prefer"        = "resolution=merge-duplicates"
    }

    $uri = "$SupabaseUrl/rest/v1/$Table"
    
    $maxRetries = 3
    $retry = 0
    $success = $false

    while (-not $success -and $retry -lt $maxRetries) {
        try {
            $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 60
            $success = $true
        } catch {
            $retry++
            $status = $_.Exception.Response.StatusCode.value__
            if ($status -eq 404) {
                throw "Tabela '$Table' não encontrada no Supabase. Certifique-se de ter executado 'migration_pizza10_schema.sql' no SQL Editor do Supabase."
            }
            if ($retry -ge $maxRetries) {
                Write-Host " [ERRO após $maxRetries tentativas em $Table]: $($_.Exception.Message)" -ForegroundColor Red
                throw $_
            }
            Start-Sleep -Seconds ($retry * 2)
        }
    }
}

try {
    $conn.Open()
    Write-Host " Conectado com sucesso ao SQL Server local!" -ForegroundColor Green
    Write-Host ""

    # --------------------------------------------------------------------------
    # 1. CATEGORIAS (categorias_pizza10)
    # --------------------------------------------------------------------------
    Write-Host "--- 1/5: Extraindo Categorias (categorias_pizza10) ---" -ForegroundColor White
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT Codigo, Categoria, CatInativa FROM Tab_Cad_Categorias ORDER BY Codigo"
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dtCat = New-Object System.Data.DataTable
    $adapter.Fill($dtCat) | Out-Null

    $catList = @()
    foreach ($r in $dtCat.Rows) {
        $catList += @{
            id       = [int]$r["Codigo"]
            nome     = [string]$r["Categoria"]
            inativa  = if ($r["CatInativa"] -ne [DBNull]::Value) { [bool]$r["CatInativa"] } else { $false }
        }
    }

    $catExportPath = Join-Path $dataDir "categorias_pizza10.json"
    $catList | ConvertTo-Json -Depth 5 | Set-Content -Path $catExportPath -Encoding UTF8
    Write-Host " Exportados $($catList.Count) categorias para '$catExportPath'" -ForegroundColor Gray

    if (-not $ExportOnly) {
        Write-Host " Enviando categorias para o Supabase..." -NoNewline
        try {
            Send-SupabaseBatch -Table "categorias_pizza10" -Rows $catList
            Write-Host " [OK]" -ForegroundColor Green
        } catch {
            Write-Host " [FALHA: $($_.Message)]" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # --------------------------------------------------------------------------
    # 2. PRODUTOS (produtos_pizza10)
    # --------------------------------------------------------------------------
    Write-Host "--- 2/5: Extraindo Produtos (produtos_pizza10) ---" -ForegroundColor White
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT p.*, c.Categoria AS CategoriaNome FROM Tab_Cad_Produtos p LEFT JOIN Tab_Cad_Categorias c ON p.CodCategoria = c.Codigo ORDER BY p.Codigo"
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dtProd = New-Object System.Data.DataTable
    $adapter.Fill($dtProd) | Out-Null

    $prodList = @()
    foreach ($r in $dtProd.Rows) {
        $desc = ""
        if ($r.Table.Columns.Contains("Descritivo") -and $r["Descritivo"] -ne [DBNull]::Value) {
            $desc = [string]$r["Descritivo"]
        } elseif ($r.Table.Columns.Contains("Caracteristicas") -and $r["Caracteristicas"] -ne [DBNull]::Value) {
            $desc = [string]$r["Caracteristicas"]
        }

        # Obter preco por indice de coluna ou busca flexivel
        $preco = 0.0
        foreach ($col in $r.Table.Columns) {
            if ($col.ColumnName -like "*Pre*o_Lista" -and $col.ColumnName -notlike "*Data*") {
                if ($r[$col] -ne [DBNull]::Value) { $preco = [double]$r[$col] }
                break
            }
        }
        $custo = 0.0
        if ($r.Table.Columns.Contains("Valorcusto") -and $r["Valorcusto"] -ne [DBNull]::Value) { $custo = [double]$r["Valorcusto"] }

        $ativo = $true
        if ($r.Table.Columns.Contains("Inativo") -and $r["Inativo"] -ne [DBNull]::Value) { $ativo = -not [bool]$r["Inativo"] }

        $delivery = $true
        if ($r.Table.Columns.Contains("AVenda_Delivery") -and $r["AVenda_Delivery"] -ne [DBNull]::Value) { $delivery = [bool]$r["AVenda_Delivery"] }

        $prodList += @{
            id             = [int]$r["Codigo"]
            categoria_id   = if ($r["CodCategoria"] -ne [DBNull]::Value) { [int]$r["CodCategoria"] } else { $null }
            categoria_nome = if ($r["CategoriaNome"] -ne [DBNull]::Value) { [string]$r["CategoriaNome"] } else { $null }
            nome           = [string]$r["Descricao"]
            descricao      = $desc
            preco          = [math]::Round($preco, 2)
            preco_custo    = [math]::Round($custo, 2)
            unidade        = if ($r["Unidade"] -ne [DBNull]::Value) { [string]$r["Unidade"] } else { "UN" }
            codigo_barras  = if ($r["CodBarras"] -ne [DBNull]::Value) { [string]$r["CodBarras"] } else { $null }
            ativo          = $ativo
            delivery       = $delivery
            balcao         = $true
            mesa           = $true
        }
    }

    $prodExportPath = Join-Path $dataDir "produtos_pizza10.json"
    $prodList | ConvertTo-Json -Depth 5 | Set-Content -Path $prodExportPath -Encoding UTF8
    Write-Host " Exportados $($prodList.Count) produtos para '$prodExportPath'" -ForegroundColor Gray

    if (-not $ExportOnly) {
        Write-Host " Enviando produtos para o Supabase..." -NoNewline
        try {
            Send-SupabaseBatch -Table "produtos_pizza10" -Rows $prodList
            Write-Host " [OK]" -ForegroundColor Green
        } catch {
            Write-Host " [FALHA: $($_.Message)]" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # --------------------------------------------------------------------------
    # 3. CLIENTES + TELEFONES (clientes_pizza10)
    # --------------------------------------------------------------------------
    Write-Host "--- 3/5: Extraindo Clientes e Telefones (clientes_pizza10) ---" -ForegroundColor White
    
    # Carregar todos os telefones secundários em hashtable para lookup rápido
    Write-Host " Carregando catálogo de telefones..." -NoNewline
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT Cliente, Telefone, Compl_Fone FROM Tab_Cad_Clientes_Telefones WHERE Telefone IS NOT NULL"
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dtPhones = New-Object System.Data.DataTable
    $adapter.Fill($dtPhones) | Out-Null
    
    $phoneMap = @{}
    foreach ($pr in $dtPhones.Rows) {
        $cId = [int]$pr["Cliente"]
        $tel = [string]$pr["Telefone"]
        if (-not $phoneMap.ContainsKey($cId)) {
            $phoneMap[$cId] = [System.Collections.Generic.List[string]]::new()
        }
        if (-not [string]::IsNullOrWhiteSpace($tel)) {
            $phoneMap[$cId].Add($tel)
        }
    }
    Write-Host " ($($dtPhones.Rows.Count) números mapeados)" -ForegroundColor Gray

    # Extrair clientes com JOIN em Bairros e Municípios para endereço 100% completo
    Write-Host " Carregando 47.361 clientes com bairros e cidades do SQL Server..." -NoNewline
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = @"
    SELECT 
        c.Codigo, c.RazaoSocial, c.Resumido, c.Contato, c.CGC, c.CPFCNPJ_Num, c.Inscricao, c.Telefones, c.EMail,
        c.CEP, c.Endereco, c.Endereco_Numero, c.Endereco_Complemento,
        COALESCE(c.Bairrox, b.Bairro) AS BairroResolvido,
        COALESCE(c.Cidadex, m.Municipio, 'Itatiba') AS CidadeResolvida,
        c.Estado,
        c.Observacao, c.Preferencia, c.Limite_de_Credito, c.Consumo_Total, c.Qtd_Pedidos,
        c.Data_Ultimo_Pedido, c.Inativo, c.Cadastro, c.TimeStampx
    FROM Tab_Cad_Clientes c
    LEFT JOIN Tab_Cad_Bairros b ON c.Cod_Bairro = b.Codigo
    LEFT JOIN Tab_Cad_Municipios m ON c.CodMunicipio = m.Codigo
    ORDER BY c.Codigo
"@
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dtCli = New-Object System.Data.DataTable
    $adapter.Fill($dtCli) | Out-Null
    Write-Host " [OK: $($dtCli.Rows.Count) registros]" -ForegroundColor Green

    $cliExportPath = Join-Path $dataDir "clientes_pizza10.jsonl"
    $cliFileStream = [System.IO.StreamWriter]::new($cliExportPath, $false, [System.Text.Encoding]::UTF8)

    $batch = @()
    $totalSent = 0
    $totalCli = $dtCli.Rows.Count

    for ($i = 0; $i -lt $totalCli; $i++) {
        $r = $dtCli.Rows[$i]
        $cId = [int]$r["Codigo"]

        $razao = [string]$r["RazaoSocial"]
        $resumido = [string]$r["Resumido"]
        $contato = [string]$r["Contato"]

        # Trata nomes vazios ou "cliente" genérico
        $nome = $razao
        if ([string]::IsNullOrWhiteSpace($nome) -or $nome.Trim().ToLower() -eq "cliente") {
            if (-not [string]::IsNullOrWhiteSpace($contato) -and $contato.Trim().ToLower() -ne "cliente") {
                $nome = $contato
            } elseif (-not [string]::IsNullOrWhiteSpace($resumido) -and $resumido.Trim().ToLower() -ne "cliente") {
                $nome = $resumido
            }
        }
        if ([string]::IsNullOrWhiteSpace($nome)) {
            $nome = "Cliente #$cId"
        }

        # Telefones agregados
        $telList = [System.Collections.Generic.List[string]]::new()
        if ($r["Telefones"] -ne [DBNull]::Value -and [string]$r["Telefones"] -ne "") {
            $telList.Add([string]$r["Telefones"])
        }
        if ($phoneMap.ContainsKey($cId)) {
            foreach ($t in $phoneMap[$cId]) {
                if (-not $telList.Contains($t)) {
                    $telList.Add($t)
                }
            }
        }

        $telPrincipal = if ($telList.Count -gt 0) { $telList[0] } else { $null }

        # Documento
        $doc = [string]$r["CGC"]
        if ([string]::IsNullOrWhiteSpace($doc) -and $r["CPFCNPJ_Num"] -ne [DBNull]::Value) {
            $doc = [string]$r["CPFCNPJ_Num"]
        }

        # Observações
        $obs = [string]$r["Observacao"]
        if ($r["Preferencia"] -ne [DBNull]::Value -and [string]$r["Preferencia"] -ne "") {
            if (-not [string]::IsNullOrWhiteSpace($obs)) { $obs += " | " }
            $obs += "Pref: " + [string]$r["Preferencia"]
        }

        $limite = if ($r["Limite_de_Credito"] -ne [DBNull]::Value) { [double]$r["Limite_de_Credito"] } else { 0.0 }
        $consumo = if ($r["Consumo_Total"] -ne [DBNull]::Value) { [double]$r["Consumo_Total"] } else { 0.0 }
        $qtdPed = if ($r["Qtd_Pedidos"] -ne [DBNull]::Value) { [int]$r["Qtd_Pedidos"] } else { 0 }

        $dataUltimoPed = if ($r["Data_Ultimo_Pedido"] -ne [DBNull]::Value) { ([datetime]$r["Data_Ultimo_Pedido"]).ToString("yyyy-MM-ddTHH:mm:ssZ") } else { $null }
        $dataCad = if ($r["Cadastro"] -ne [DBNull]::Value) { ([datetime]$r["Cadastro"]).ToString("yyyy-MM-ddTHH:mm:ssZ") } else { $null }
        $dataUpd = if ($r["TimeStampx"] -ne [DBNull]::Value) { ([datetime]$r["TimeStampx"]).ToString("yyyy-MM-ddTHH:mm:ssZ") } else { $null }

        $bairro = if ($r["BairroResolvido"] -ne [DBNull]::Value) { ([string]$r["BairroResolvido"]).Trim() } else { $null }
        $cidade = if ($r["CidadeResolvida"] -ne [DBNull]::Value) { ([string]$r["CidadeResolvida"]).Trim() } else { "Itatiba" }
        $estado = if ($r["Estado"] -ne [DBNull]::Value -and [string]$r["Estado"] -ne "") { ([string]$r["Estado"]).Trim() } else { "SP" }

        $cliObj = @{
            id                 = $cId
            nome               = $nome.Trim()
            razao_social       = if ($r["RazaoSocial"] -ne [DBNull]::Value) { ([string]$r["RazaoSocial"]).Trim() } else { $null }
            nome_fantasia      = if ($r["Resumido"] -ne [DBNull]::Value) { ([string]$r["Resumido"]).Trim() } else { $null }
            documento          = if (-not [string]::IsNullOrWhiteSpace($doc)) { $doc.Trim() } else { $null }
            rg_ie              = if ($r["Inscricao"] -ne [DBNull]::Value) { ([string]$r["Inscricao"]).Trim() } else { $null }
            telefone_principal = $telPrincipal
            telefones          = $telList
            email              = if ($r["EMail"] -ne [DBNull]::Value) { ([string]$r["EMail"]).Trim() } else { $null }
            cep                = if ($r["CEP"] -ne [DBNull]::Value) { ([string]$r["CEP"]).Trim() } else { $null }
            endereco           = if ($r["Endereco"] -ne [DBNull]::Value) { ([string]$r["Endereco"]).Trim() } else { $null }
            numero             = if ($r["Endereco_Numero"] -ne [DBNull]::Value) { ([string]$r["Endereco_Numero"]).Trim() } else { $null }
            complemento        = if ($r["Endereco_Complemento"] -ne [DBNull]::Value) { ([string]$r["Endereco_Complemento"]).Trim() } else { $null }
            bairro             = $bairro
            cidade             = $cidade
            estado             = $estado
            observacao         = if (-not [string]::IsNullOrWhiteSpace($obs)) { $obs.Trim() } else { $null }
            limite_credito     = [math]::Round($limite, 2)
            consumo_total      = [math]::Round($consumo, 2)
            qtd_pedidos        = $qtdPed
            data_ultimo_pedido = $dataUltimoPed
            inativo            = if ($r["Inativo"] -ne [DBNull]::Value) { [bool]$r["Inativo"] } else { $false }
            created_at         = $dataCad
            updated_at         = $dataUpd
        }

        # Gravar no JSONL de backup local
        $cliFileStream.WriteLine(($cliObj | ConvertTo-Json -Depth 3 -Compress))
        $batch += $cliObj

        if ($batch.Count -ge $BatchSize -or $i -eq ($totalCli - 1)) {
            if (-not $ExportOnly) {
                try {
                    Send-SupabaseBatch -Table "clientes_pizza10" -Rows $batch
                } catch {
                    Write-Host "`n [AVISO no lote clientes]: $($_.Message)" -ForegroundColor Yellow
                }
            }
            $totalSent += $batch.Count
            $pct = [math]::Round(($totalSent / $totalCli) * 100, 1)
            Write-Progress -Activity "Migrando Clientes" -Status "$totalSent / $totalCli ($pct%)" -PercentComplete $pct
            $batch = @()
        }
    }

    $cliFileStream.Close()
    Write-Host " Clientes: $totalCli processados e salvos em '$cliExportPath'" -ForegroundColor Green
    Write-Host ""

    # --------------------------------------------------------------------------
    # 4. PEDIDOS (pedidos_pizza10)
    # --------------------------------------------------------------------------
    Write-Host "--- 4/5: Extraindo Pedidos (pedidos_pizza10) ---" -ForegroundColor White
    Write-Host " Carregando 313.985 pedidos do SQL Server..." -NoNewline

    $pedExportPath = Join-Path $dataDir "pedidos_pizza10.jsonl"
    $pedFileStream = [System.IO.StreamWriter]::new($pedExportPath, $false, [System.Text.Encoding]::UTF8)

    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 300
    $cmd.CommandText = @"
    SELECT 
        p.Pedido, p.CodCliente, c.RazaoSocial AS ClienteNome, p.Telefone, p.Data, p.Tipo,
        p.Entregue, p.Fechado, p.Total_Produtos, p.Desconto_Cliente, p.Desconto_Adicional,
        p.Tx_Entrega, p.Total_Pedido, p.Codigo_FormaPG, p.Pgto_Dinheiro, p.Pgto_Cartao,
        p.Pgto_Cheque, p.Pgto_Outros, p.Pgto_Troco, p.Mesa, p.Atendente, p.Entregador,
        p.Observacao, p.Complemento_Cliente
    FROM Tab_Vnd_Pedidos p
    LEFT JOIN Tab_Cad_Clientes c ON p.CodCliente = c.Codigo
    WHERE (p.CodCliente IS NOT NULL OR (c.RazaoSocial IS NOT NULL AND c.RazaoSocial <> '') OR p.Total_Pedido > 0)
    ORDER BY p.Pedido
"@
    $reader = $cmd.ExecuteReader()
    Write-Host " [Leitura iniciada...]" -ForegroundColor Cyan

    $pedBatch = @()
    $pedCount = 0

    while ($reader.Read()) {
        $pedId = [int]$reader["Pedido"]
        $dtPed = if ($reader["Data"] -ne [DBNull]::Value) { ([datetime]$reader["Data"]).ToString("yyyy-MM-ddTHH:mm:ssZ") } else { (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") }
        
        # Status
        $entregue = if ($reader["Entregue"] -ne [DBNull]::Value) { [bool]$reader["Entregue"] } else { $false }
        $fechado = if ($reader["Fechado"] -ne [DBNull]::Value) { [bool]$reader["Fechado"] } else { $false }
        $statusStr = if ($entregue) { "entregue" } elseif ($fechado) { "entregue" } else { "novo" }

        $totProd = if ($reader["Total_Produtos"] -ne [DBNull]::Value) { [double]$reader["Total_Produtos"] } else { 0.0 }
        $descCli = if ($reader["Desconto_Cliente"] -ne [DBNull]::Value) { [double]$reader["Desconto_Cliente"] } else { 0.0 }
        $descAdic = if ($reader["Desconto_Adicional"] -ne [DBNull]::Value) { [double]$reader["Desconto_Adicional"] } else { 0.0 }
        $taxa = if ($reader["Tx_Entrega"] -ne [DBNull]::Value) { [double]$reader["Tx_Entrega"] } else { 0.0 }
        $totPed = if ($reader["Total_Pedido"] -ne [DBNull]::Value) { [double]$reader["Total_Pedido"] } else { 0.0 }

        $pedObj = @{
            id                  = $pedId
            cliente_id          = if ($reader["CodCliente"] -ne [DBNull]::Value) { [int]$reader["CodCliente"] } else { $null }
            cliente_nome        = if ($reader["ClienteNome"] -ne [DBNull]::Value) { ([string]$reader["ClienteNome"]).Trim() } else { $null }
            cliente_telefone    = if ($reader["Telefone"] -ne [DBNull]::Value) { ([string]$reader["Telefone"]).Trim() } else { $null }
            data_pedido         = $dtPed
            tipo_pedido         = if ($reader["Tipo"] -ne [DBNull]::Value) { [int]$reader["Tipo"] } else { 1 }
            status              = $statusStr
            total_produtos      = [math]::Round($totProd, 2)
            total_desconto      = [math]::Round($descCli + $descAdic, 2)
            taxa_entrega        = [math]::Round($taxa, 2)
            total_pedido        = [math]::Round($totPed, 2)
            forma_pagamento_id  = if ($reader["Codigo_FormaPG"] -ne [DBNull]::Value) { [int]$reader["Codigo_FormaPG"] } else { $null }
            pgto_dinheiro       = if ($reader["Pgto_Dinheiro"] -ne [DBNull]::Value) { [math]::Round([double]$reader["Pgto_Dinheiro"], 2) } else { 0.0 }
            pgto_cartao         = if ($reader["Pgto_Cartao"] -ne [DBNull]::Value) { [math]::Round([double]$reader["Pgto_Cartao"], 2) } else { 0.0 }
            pgto_cheque         = if ($reader["Pgto_Cheque"] -ne [DBNull]::Value) { [math]::Round([double]$reader["Pgto_Cheque"], 2) } else { 0.0 }
            pgto_outros         = if ($reader["Pgto_Outros"] -ne [DBNull]::Value) { [math]::Round([double]$reader["Pgto_Outros"], 2) } else { 0.0 }
            pgto_troco          = if ($reader["Pgto_Troco"] -ne [DBNull]::Value) { [math]::Round([double]$reader["Pgto_Troco"], 2) } else { 0.0 }
            mesa                = if ($reader["Mesa"] -ne [DBNull]::Value) { [int]$reader["Mesa"] } else { $null }
            atendente           = if ($reader["Atendente"] -ne [DBNull]::Value) { ([string]$reader["Atendente"]).Trim() } else { $null }
            entregador          = if ($reader["Entregador"] -ne [DBNull]::Value) { ([string]$reader["Entregador"]).Trim() } else { $null }
            observacao          = if ($reader["Observacao"] -ne [DBNull]::Value) { ([string]$reader["Observacao"]).Trim() } else { $null }
            endereco_entrega    = if ($reader["Complemento_Cliente"] -ne [DBNull]::Value) { ([string]$reader["Complemento_Cliente"]).Trim() } else { $null }
            created_at          = $dtPed
        }

        $pedFileStream.WriteLine(($pedObj | ConvertTo-Json -Depth 3 -Compress))
        $pedBatch += $pedObj
        $pedCount++

        if ($pedBatch.Count -ge $BatchSize) {
            if (-not $ExportOnly) {
                try {
                    Send-SupabaseBatch -Table "pedidos_pizza10" -Rows $pedBatch
                } catch {
                    # Continue stream
                }
            }
            $pct = [math]::Round(($pedCount / 313985) * 100, 1)
            Write-Progress -Activity "Processando Pedidos" -Status "$pedCount pedidos ($pct%)" -PercentComplete $pct
            $pedBatch = @()
        }
    }
    $reader.Close()

    if ($pedBatch.Count -gt 0 -and -not $ExportOnly) {
        try { Send-SupabaseBatch -Table "pedidos_pizza10" -Rows $pedBatch } catch {}
    }

    $pedFileStream.Close()
    Write-Host " Pedidos: $pedCount processados e salvos em '$pedExportPath'" -ForegroundColor Green
    Write-Host ""

    # --------------------------------------------------------------------------
    # 5. ITENS DE PEDIDOS (pedidos_itens_pizza10)
    # --------------------------------------------------------------------------
    Write-Host "--- 5/5: Extraindo Itens de Pedidos (pedidos_itens_pizza10) ---" -ForegroundColor White
    Write-Host " Carregando 1.016.756 itens do SQL Server..." -NoNewline

    $itemExportPath = Join-Path $dataDir "pedidos_itens_pizza10.jsonl"
    $itemFileStream = [System.IO.StreamWriter]::new($itemExportPath, $false, [System.Text.Encoding]::UTF8)

    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 600
    $cmd.CommandText = @"
    SELECT 
        Codigo, Pedido, Produto, Descricao, Descricao_FazNaHora, Quantidade,
        Unitario, Total, VlrDesconto, Descritivo, ItemCancelado, Data
    FROM Tab_Vnd_Pedidos_Itens
    WHERE Pedido IS NOT NULL
    ORDER BY Codigo
"@
    $reader = $cmd.ExecuteReader()
    Write-Host " [Leitura de itens iniciada...]" -ForegroundColor Cyan

    $itemBatch = @()
    $itemCount = 0

    while ($reader.Read()) {
        $desc = [string]$reader["Descricao"]
        if ([string]::IsNullOrWhiteSpace($desc) -and $reader["Descricao_FazNaHora"] -ne [DBNull]::Value) {
            $desc = [string]$reader["Descricao_FazNaHora"]
        }
        if ([string]::IsNullOrWhiteSpace($desc)) {
            $desc = "Item"
        }

        $obs = ""
        if ($reader["Descritivo"] -ne [DBNull]::Value -and [string]$reader["Descritivo"] -ne "") {
            $obs = [string]$reader["Descritivo"]
        }

        $qtd = if ($reader["Quantidade"] -ne [DBNull]::Value) { [double]$reader["Quantidade"] } else { 1.0 }
        $unit = if ($reader["Unitario"] -ne [DBNull]::Value) { [double]$reader["Unitario"] } else { 0.0 }
        $tot = if ($reader["Total"] -ne [DBNull]::Value) { [double]$reader["Total"] } else { 0.0 }
        $descVal = if ($reader["VlrDesconto"] -ne [DBNull]::Value) { [double]$reader["VlrDesconto"] } else { 0.0 }

        $dtItem = if ($reader["Data"] -ne [DBNull]::Value) { ([datetime]$reader["Data"]).ToString("yyyy-MM-ddTHH:mm:ssZ") } else { $null }

        $itemObj = @{
            item_codigo    = [int]$reader["Codigo"]
            pedido_id      = [int]$reader["Pedido"]
            produto_id     = if ($reader["Produto"] -ne [DBNull]::Value) { [int]$reader["Produto"] } else { $null }
            descricao      = $desc.Trim()
            quantidade     = [math]::Round($qtd, 3)
            preco_unitario = [math]::Round($unit, 2)
            preco_total    = [math]::Round($tot, 2)
            desconto       = [math]::Round($descVal, 2)
            observacao     = if (-not [string]::IsNullOrWhiteSpace($obs)) { $obs.Trim() } else { $null }
            cancelado      = if ($reader["ItemCancelado"] -ne [DBNull]::Value) { [bool]$reader["ItemCancelado"] } else { $false }
            created_at     = $dtItem
        }

        $itemFileStream.WriteLine(($itemObj | ConvertTo-Json -Depth 3 -Compress))
        $itemBatch += $itemObj
        $itemCount++

        if ($itemBatch.Count -ge ($BatchSize * 2)) {
            if (-not $ExportOnly) {
                try {
                    Send-SupabaseBatch -Table "pedidos_itens_pizza10" -Rows $itemBatch
                } catch {
                    # Continue stream
                }
            }
            $pct = [math]::Round(($itemCount / 1016756) * 100, 1)
            Write-Progress -Activity "Processando Itens" -Status "$itemCount itens ($pct%)" -PercentComplete $pct
            $itemBatch = @()
        }
    }
    $reader.Close()

    if ($itemBatch.Count -gt 0 -and -not $ExportOnly) {
        try { Send-SupabaseBatch -Table "pedidos_itens_pizza10" -Rows $itemBatch } catch {}
    }

    $itemFileStream.Close()
    Write-Host " Itens: $itemCount processados e salvos em '$itemExportPath'" -ForegroundColor Green
    Write-Host ""

    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "   MIGRAÇÃO E EXTRAÇÃO CONCLUÍDAS COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "Arquivos gerados em: $dataDir" -ForegroundColor White
    Write-Host "  - categorias_pizza10.json" -ForegroundColor Gray
    Write-Host "  - produtos_pizza10.json" -ForegroundColor Gray
    Write-Host "  - clientes_pizza10.jsonl" -ForegroundColor Gray
    Write-Host "  - pedidos_pizza10.jsonl" -ForegroundColor Gray
    Write-Host "  - pedidos_itens_pizza10.jsonl" -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "`n❌ ERRO DURANTE A EXECUÇÃO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    if ($conn.State -eq [System.Data.ConnectionState]::Open) {
        $conn.Close()
    }
}
