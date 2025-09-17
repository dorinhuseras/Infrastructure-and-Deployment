$tenantId = "088d4db9-9b6c-4e6e-9443-445753fb73fe"
$SqlServerName = "exersicelab2"
$SqlDatabaseName = "demo-database"
$MiName = "DorinTrnNewEnvAsb"

function Set-DbRoles-To-Mi {
    param (
        [String] $sqlServerName,
        [String] $sqlDatabaseName,
        [String] $miName
    )
    Write-Host $miName
    Write-Host "Insert identity $miName to $sqlDatabaseName from $sqlServerName Sql Server"
    $query = "
    IF NOT EXISTS (select name as username from sys.database_principals where name = '$miName')
        BEGIN
                CREATE USER [$miName] FROM EXTERNAL PROVIDER;
                ALTER ROLE db_datareader ADD MEMBER [$miName];
                ALTER ROLE db_datawriter ADD MEMBER [$miName];
                ALTER ROLE db_owner ADD MEMBER [$miName];
        END
    ;
    "

    $Params = @{
        'ServerInstance' = ($sqlServerName + ".database.windows.net");
        'Database' = $sqlDatabaseName;
        'AccessToken' = (Get-AzAccessToken -ResourceUrl https://database.windows.net -TenantID $tenantId).Token ;
        'Query' = $query;
    }

    Write-Host "Excecute SQL Query"
    Invoke-Sqlcmd @Params
    Write-Host "Excecuted SQL Query"
}

function Main{
    Set-DbRoles-To-Mi -SqlServerName $SqlServerName -SqlDatabaseName $SqlDatabaseName -miName $MiName
}

Main