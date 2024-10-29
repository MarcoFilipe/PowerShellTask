param (
    [string]$SourceFolder,     # Path to the source folder
    [string]$ReplicaFolder,    # Path to the replica folder
    [string]$LogFilePath       # Path to the log file
)


# Function to synchronize content from Source to Replica folder
function Sync-Folders {
    param (
        [string]$Source,
        [string]$Replica
    )

    # Folder exists ?
    if (!(Test-Path -Path $Replica)) {
        New-Item -ItemType Directory -Path $Replica | Out-Null
        Log-Message "Created replica folder: $Replica"
    }

    # Get Items
    $SourceItems = Get-ChildItem -Path $Source -Recurse

    # Copy or update items from source to replica
    foreach ($Item in $SourceItems) {
        $ReplicaItemPath = $Replica + $Item.FullName.Substring($Source.Length)  #Get Item path
        $ReplicaLastWriteTime = $null

        if ($Item.PSIsContainer) {
            # Create folder if it doesn't exist
            if (!(Test-Path -Path $ReplicaItemPath)) {
                New-Item -ItemType Directory -Path $ReplicaItemPath | Out-Null
                Log-Message "Folder Created: $ReplicaItemPath"
            }
        } else {
            # Copy or update file
            if (-not (Test-Path -Path $ReplicaItemPath) -or ($Item.LastWriteTime -gt $ReplicaLastWriteTime)) {
                Copy-Item -Path $Item.FullName -Destination $ReplicaItemPath -Force
                Log-Message "File Copied/Updated: $ReplicaItemPath"
            }
        }
    }

    # Remove items from the replica that do not exist in the source
    $ReplicaItems = Get-ChildItem -Path $Replica -Recurse
    foreach ($Item in $ReplicaItems) {
        $SourceItemPath = $Source + $Item.FullName.Substring($Replica.Length)
        if (!(Test-Path -Path $SourceItemPath)) {
            if ($Item.PSIsContainer) {
                Remove-Item -Path $Item.FullName -Recurse -Force
                Log-Message "Removed folder: $Item.FullName"
            } else {
                Remove-Item -Path $Item.FullName -Force
                Log-Message "Removed file: $Item.FullName"
            }
        }
    }
}

# Function to log messages with current time
function Log-Message {
    param (
        [string]$Message
    )
    $CurrentTime = Get-Date -Format "dd-mm-yyyy HH:mm:ss" # Using PT format
    $LogEntry = "$CurrentTime - $Message"
    Write-Output $LogEntry
    Add-Content -Path $LogFilePath -Value $LogEntry
}


#Test if the folders exist

if (!(Test-Path -Path $SourceFolder)) {
    Write-Error "Source folder does not exist: $SourceFolder"
    exit
}
if (!(Test-Path -Path (Split-Path -Path $LogFilePath -Parent))) {
    Write-Error "Log file directory does not exist: $(Split-Path -Path $LogFilePath -Parent)"
    exit
}

Log-Message "Starting synchronization from $SourceFolder to $ReplicaFolder"
Sync-Folders -Source $SourceFolder -Replica $ReplicaFolder
Log-Message "Synchronization completed"
