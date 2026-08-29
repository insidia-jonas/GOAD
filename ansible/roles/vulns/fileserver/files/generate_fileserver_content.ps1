# Generates a realistic corporate file-server tree for the GOAD lab.
# Compatible with Windows Server 2012 R2 / PowerShell 4.0.
param(
    [string]$Root = 'C:\FileServer',
    [int]$FilesPerShare = 40,
    [bool]$PlantSqlCredentials = $true,
    [string]$CastelblackSa = '',
    [string]$BraavosSa = '',
    [string]$SqlSvcPassword = ''
)

$ErrorActionPreference = 'Continue'

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-TextFile([string]$Path, [string]$Content) {
    $dir = Split-Path -Parent $Path
    Ensure-Dir $dir
    Set-Content -LiteralPath $Path -Value $Content -Encoding ASCII
}

$departments = @(
    @{ Name = 'Finance';  Subs = @('Budgets', 'Invoices', 'Payroll', 'Audits') },
    @{ Name = 'HR';       Subs = @('Employees', 'Onboarding', 'Policies', 'Reviews') },
    @{ Name = 'Legal';    Subs = @('Contracts', 'NDA', 'Litigation', 'Templates') },
    @{ Name = 'IT';       Subs = @('Configs', 'Runbooks', 'SQL', 'Backups') },
    @{ Name = 'SQL';      Subs = @('ConnectionStrings', 'Exports', 'Jobs', 'Notes') },
    @{ Name = 'Public';   Subs = @('Memos', 'Newsletters', 'Forms', 'Shared') },
    @{ Name = 'Archives'; Subs = @('Citadel', 'Oldtown', 'Scrolls', 'Maps') }
)

$firstNames = @('Jon','Arya','Sansa','Robb','Bran','Catelyn','Ned','Samwell','Jeor','Daenerys','Missandei','Grey','Tyrion','Cersei','Jaime','Robert','Renly','Stannis','Petyr','Varys','Pycelle','Qyburn','Sandor','Gregor','Jorah','Khal')
$lastNames  = @('Snow','Stark','Tarly','Mormont','Targaryen','Worm','Lannister','Baratheon','Baelish','Payne','Clegane','Drogo')
$cities     = @('Winterfell','Kings Landing','Castle Black','Oldtown','Braavos','Meereen','Harrenhal','The Eyrie','Casterly Rock','Dragonstone')
$titles     = @('Steward','Ranger','Maester','Septa','Captain','Clerk','Treasurer','Scribe','Envoy','Warden')

function Get-Pick($arr, $i) { return $arr[$i % $arr.Length] }

function New-Person([int]$i) {
    $fn = Get-Pick $firstNames $i
    $ln = Get-Pick $lastNames ($i * 3)
    return @{
        First = $fn
        Last  = $ln
        User  = ($fn.ToLower() + '.' + $ln.ToLower())
        City  = Get-Pick $cities $i
        Title = Get-Pick $titles $i
        Year  = 280 + ($i % 20)
    }
}

Ensure-Dir $Root

# Discover existing share folders under root (created by Ansible) and always seed defaults
$shareNames = New-Object System.Collections.ArrayList
Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    [void]$shareNames.Add($_.Name)
}
foreach ($dept in $departments) {
    $path = Join-Path $Root $dept.Name
    Ensure-Dir $path
    if (-not $shareNames.Contains($dept.Name)) {
        [void]$shareNames.Add($dept.Name)
    }
}

foreach ($dept in $departments) {
    $deptRoot = Join-Path $Root $dept.Name
    foreach ($sub in $dept.Subs) {
        Ensure-Dir (Join-Path $deptRoot $sub)
    }

    for ($n = 1; $n -le $FilesPerShare; $n++) {
        $p = New-Person ($n + $dept.Name.Length)
        $sub = Get-Pick $dept.Subs $n
        $folder = Join-Path $deptRoot $sub
        $kind = $n % 7

        switch ($kind) {
            0 {
                $name = ('memo_{0:D3}_{1}.txt' -f $n, $p.User)
                $body = @"
SEVEN KINGDOMS - INTERNAL MEMORANDUM
From: $($p.First) $($p.Last) <$($p.User)@sevenkingdoms.local>
Office: $($p.City)
Date: $($p.Year)-$((($n % 12)+1).ToString('00'))-$((($n % 28)+1).ToString('00'))
Subject: $sub update #$n

The $sub desk in $($p.City) completed the weekly tally.
Please archive a copy on the file server and notify the Small Council if
figures deviate more than 5 percent from last moon.

--
$($p.Title) $($p.Last)
Do not forward outside the realm.
"@
                Write-TextFile (Join-Path $folder $name) $body
            }
            1 {
                $name = ('register_{0:D3}.csv' -f $n)
                $lines = @('id,name,office,title,amount,currency,notes')
                for ($r = 0; $r -lt 12; $r++) {
                    $q = New-Person ($n * 10 + $r)
                    $amt = 100 + (($n * 17 + $r * 13) % 9800)
                    $lines += ('{0},{1} {2},{3},{4},{5},gold,{6}' -f ($n * 100 + $r), $q.First, $q.Last, $q.City, $q.Title, $amt, $sub)
                }
                Write-TextFile (Join-Path $folder $name) ($lines -join "`r`n")
            }
            2 {
                $name = ('policy_{0:D3}.md' -f $n)
                $body = @"
# $($dept.Name) policy $n

1. Access to \\oldtown\$($dept.Name) is limited to domain users.
2. Confidential scrolls stay in $sub.
3. Contact $($p.User)@sevenkingdoms.local for exceptions.
4. Retention: $($p.Year) years after the War for the Dawn.

Last reviewed by $($p.First) $($p.Last).
"@
                Write-TextFile (Join-Path $folder $name) $body
            }
            3 {
                $name = ('invoice_{0:D4}.txt' -f (1000 + $n))
                $body = @"
INVOICE INV-$($dept.Name.ToUpper())-$n
Bill To: The Crown, King's Landing
Ship To: $($p.City)
Item: $sub services for moon $n
Quantity: $((($n % 9) + 1))
Unit:  $((50 + $n)) gold dragons
Total: $(( (50 + $n) * (($n % 9) + 1) )) gold dragons
Payment: payable to the Iron Bank / transfer to the royal ledger
Prepared by: $($p.First) $($p.Last)
"@
                Write-TextFile (Join-Path $folder $name) $body
            }
            4 {
                $name = ('email_{0:D3}.eml' -f $n)
                $body = @"
From: $($p.User)@sevenkingdoms.local
To: maester.pycelle@sevenkingdoms.local
Subject: $sub - document $n
Date: $($p.Year)-01-15

Maester,

Attached is the $sub extract for cycle $n. I also left a copy on
\\oldtown\$($dept.Name)\$sub.

Regards,
$($p.First)
"@
                Write-TextFile (Join-Path $folder $name) $body
            }
            5 {
                $name = ('notes_{0:D3}.log' -f $n)
                $body = @"
[$($p.Year)-06-01 08:15] $($p.User) opened $sub ledger
[$($p.Year)-06-01 08:22] export started
[$($p.Year)-06-01 08:41] export finished rows=$((120 + $n))
[$($p.Year)-06-01 09:02] copied to \\oldtown\$($dept.Name)
"@
                Write-TextFile (Join-Path $folder $name) $body
            }
            default {
                $name = ('record_{0:D3}.xml' -f $n)
                $body = @"
<?xml version="1.0" encoding="utf-8"?>
<record id="$n" department="$($dept.Name)" office="$($p.City)">
  <owner>$($p.First) $($p.Last)</owner>
  <title>$($p.Title)</title>
  <folder>$sub</folder>
  <classification>internal</classification>
</record>
"@
                Write-TextFile (Join-Path $folder $name) $body
            }
        }
    }
}

if ($PlantSqlCredentials) {
    $sqlRoot = Join-Path $Root 'SQL\ConnectionStrings'
    $itSql   = Join-Path $Root 'IT\SQL'
    Ensure-Dir $sqlRoot
    Ensure-Dir $itSql
    Ensure-Dir (Join-Path $Root 'Finance\Audits')
    Ensure-Dir (Join-Path $Root 'IT\Configs')
    Ensure-Dir (Join-Path $Root 'Archives\Citadel')

    # Values come from Ansible (lab config.json). Nothing secret is committed here.
    $cbSa = $CastelblackSa
    $brSa = $BraavosSa
    $svc  = $SqlSvcPassword

    Write-TextFile (Join-Path $itSql 'castelblack_sa.txt') @"
Castelblack MSSQL (north.sevenkingdoms.local)
=============================================
Server:   castelblack.north.sevenkingdoms.local,1433
Instance: SQLEXPRESS
Database: Kingdoms
Auth:     SQL Authentication
User:     sa
Password: $cbSa

Linked server: BRAAVOS -> sa / $brSa

Windows service account:
  NORTH\sql_svc
  $svc

Sysadmin (Windows): NORTH\jon.snow
Keep this file on the IT share only. -- Jeor
"@

    Write-TextFile (Join-Path $itSql 'braavos_sa.txt') @"
Braavos MSSQL (essos.local)
===========================
Server:   braavos.essos.local,1433
Instance: SQLEXPRESS
Database: FreeCities
Auth:     SQL Authentication
User:     sa
Password: $brSa

Linked server: CASTELBLACK -> sa / $cbSa

Windows service account:
  ESSOS\sql_svc
  $svc

Sysadmin (Windows): ESSOS\khal.drogo
"@

    Write-TextFile (Join-Path $itSql 'web.config') @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <connectionStrings>
    <add name="Castelblack" connectionString="Server=castelblack.north.sevenkingdoms.local,1433;Database=Kingdoms;User ID=sa;Password=$cbSa;TrustServerCertificate=True;" providerName="System.Data.SqlClient" />
    <add name="Braavos" connectionString="Server=braavos.essos.local,1433;Database=FreeCities;User ID=sa;Password=$brSa;TrustServerCertificate=True;" providerName="System.Data.SqlClient" />
    <add name="SqlSvcNorth" connectionString="Server=castelblack.north.sevenkingdoms.local,1433;Database=NightWatch;Integrated Security=true;" providerName="System.Data.SqlClient" />
  </connectionStrings>
  <appSettings>
    <add key="SqlSaFallback" value="$cbSa" />
  </appSettings>
</configuration>
"@

    Write-TextFile (Join-Path $sqlRoot 'RegisteredServers.xml') @"
<?xml version="1.0" encoding="utf-8"?>
<RegisteredServers>
  <Server name="castelblack" server="castelblack.north.sevenkingdoms.local,1433" auth="sql" user="sa" password="$cbSa" database="Kingdoms" />
  <Server name="braavos" server="braavos.essos.local,1433" auth="sql" user="sa" password="$brSa" database="FreeCities" />
  <Server name="sql_svc" server="castelblack.north.sevenkingdoms.local,1433" auth="windows" user="NORTH\sql_svc" password="$svc" database="NightWatch" />
</RegisteredServers>
"@

    Write-TextFile (Join-Path $sqlRoot 'ssms_connection.ini') @"
[castelblack]
server=castelblack.north.sevenkingdoms.local,1433
uid=sa
pwd=$cbSa
database=Kingdoms

[braavos]
server=braavos.essos.local,1433
uid=sa
pwd=$brSa
database=FreeCities
"@

    Write-TextFile (Join-Path $Root 'Finance\Audits\sql_accounts_review.csv') @"
system,role,username,password,reviewer,status
castelblack,sa,sa,$cbSa,pycelle,OPEN - rotate after the wedding
braavos,sa,sa,$brSa,missandei,OPEN
north,sql_svc,NORTH\sql_svc,$svc,jeor.mormont,accepted
essos,sql_svc,ESSOS\sql_svc,$svc,jorah.mormont,accepted
"@

    Write-TextFile (Join-Path $Root 'IT\Configs\appsettings.json') @"
{
  "Database": {
    "Primary": {
      "Host": "castelblack.north.sevenkingdoms.local",
      "Port": 1433,
      "Name": "Kingdoms",
      "User": "sa",
      "Password": "$cbSa"
    },
    "Linked": {
      "Host": "braavos.essos.local",
      "Port": 1433,
      "Name": "FreeCities",
      "User": "sa",
      "Password": "$brSa"
    }
  }
}
"@

    Write-TextFile (Join-Path $Root 'Archives\Citadel\legacy_sql_passwords.txt') @"
Citadel archive - do not destroy (Maester Pycelle)

Oldtown never hosted SQL, but the raven from Castle Black asked us to
store a parchment copy of the instance passwords in case Winterfell
burns again.

  sa@castelblack = $cbSa
  sa@braavos     = $brSa
  sql_svc        = $svc

Also in the night's watch runbook:
  jon.snow is sysadmin on castelblack
  khal.drogo is sysadmin on braavos
"@

    Write-TextFile (Join-Path $Root 'Public\Memos\it_notice_sql.txt') @"
NOTICE
The Citadel file server (\\oldtown) now hosts the IT and SQL shares.
Finance asked for a copy of the connection review under Finance\Audits.
If you need a database restored, raven Maester Pycelle or use the
passwords kept in IT\SQL (temporary - we know, we know).
"@
}

# Marker so Ansible can see the generator ran
Write-TextFile (Join-Path $Root '.fileserver_generated') ("generated=" + (Get-Date -Format 's') + "`r`nfiles_per_share=$FilesPerShare")
Write-Host "CHANGED: File server content generated under $Root"
