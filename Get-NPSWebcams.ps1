<#
.SYNOPSIS
    Retrieves and audits webcam data from the National Park Service (NPS) API.

.DESCRIPTION
    This script fetches webcam metadata from the NPS API, caches it locally in a JSON file, and provides auditing capabilities to find duplicate IDs, active webcams, inactive webcams, specific titles, or descriptions.

.PARAMETER findDupes
    A switch that, when present, triggers an audit of the cached data to identify and list any duplicate webcam IDs.

.PARAMETER findInactive
    A switch that, when present, triggers an audit of the cached data to identify and list webcams with a status of "Inactive".

.PARAMETER findActive
    A switch that, when present, triggers an audit of the cached data to identify and list webcams with a status of "Active".

.PARAMETER findByID
    The unique ID (UUID) of a specific webcam to find in the local cache.

.PARAMETER findTitle
    A substring to search for within the webcam titles. Search is case-insensitive and literal (no wildcards).

.PARAMETER findDescription
    A substring to search for within the webcam descriptions. Search is case-insensitive and literal (no wildcards).

.PARAMETER findStreaming
    A switch that, when present, filters and lists webcams that are currently streaming from the local cache.

.EXAMPLE
    .\Get-NPSWebcams.ps1
    Fetches the latest webcam data from the NPS API and saves it to 'nps-webcams.json'.

.EXAMPLE
    .\Get-NPSWebcams.ps1 -findDupes
    Performs a duplicate ID audit on the locally cached data.

.EXAMPLE
    .\Get-NPSWebcams.ps1 -findInactive
    Performs an audit to find all inactive webcams in the locally cached data.

.EXAMPLE
    .\Get-NPSWebcams.ps1 -findActive
    Performs an audit to find all active webcams in the locally cached data.

.EXAMPLE
    .\Get-NPSWebcams.ps1 -findTitle "Dark Sky"
    Finds and displays all webcams with "Dark Sky" in their title.

.EXAMPLE
    .\Get-NPSWebcams.ps1 -findDescription "pandas"
    Finds and displays all webcams with "pandas" in their description.

.EXAMPLE
    .\Get-NPSWebcams.ps1 -findByID "7388A31D-219C-4061-9040-272E27893264"
    Finds and displays the webcam record with the specified ID from the local cache.

.EXAMPLE
    .\Get-NPSWebcams.ps1 -findStreaming
    Filters and displays all webcams currently streaming from the local cache.

.NOTES
    Requires the 'NPS_API_KEY' environment variable to be set for API data retrieval.
    The local cache ('nps-webcams.json') is considered valid for the current calendar day.

.LINK
    https://developer.nps.gov/api/v1/webcams
#>
# Get-NPSWebcams.ps1
# Retrieves webcam data from the National Park Service (NPS) API

Param(
    [switch]$findDupes,
    [switch]$findInactive,
    [switch]$findActive,
    [string]$findByID,
    [string]$findTitle,
    [string]$findDescription,
    [switch]$findStreaming
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$outputFile = "nps-webcams.json"

# --- Cache Check ---
$shouldFetch = $true

if (Test-Path $outputFile) {
    $lastModified = (Get-Item $outputFile).LastWriteTime.Date
    $today = (Get-Date).Date

    if ($lastModified -eq $today) {
        Write-Host "Cache is valid (created today). Skipping API download."
        $shouldFetch = $false
    }
}

# If findDupes, findInactive, or findActive is requested and we don't have an API key, don't try to fetch
if (($findDupes -or $findInactive -or $findActive) -and -not $env:NPS_API_KEY) {
    if ($shouldFetch) {
        Write-Warning "NPS_API_KEY not set. Skipping fetch and proceeding to audit existing data (if any)."
        $shouldFetch = $false
    }
}

if ($shouldFetch) {
    # --- Authentication ---
    $apiKey = $env:NPS_API_KEY

    if (-not $apiKey) {
        Throw "Error: NPS_API_KEY environment variable is not set. Please set it before running this script."
    }

    Write-Host "Authentication confirmed via environment variable."

    Write-Host "Cache expired or missing. Starting API retrieval..."

    # --- API Retrieval Strategy ---
    Write-Host "Fetching total record count..."
    $initialResponse = Invoke-RestMethod -Uri "https://developer.nps.gov/api/v1/webcams?limit=1&api_key=$apiKey"
    $totalCount = $initialResponse.total

    Write-Host "Total records found: $totalCount. Retrieving all data..."
    $fullResponse = Invoke-RestMethod -Uri "https://developer.nps.gov/api/v1/webcams?limit=$totalCount&api_key=$apiKey"

    # --- File Output ---
    Write-Host "Saving results to $outputFile..."
    $fullResponse.data | ConvertTo-Json -Depth 10 | Set-Content $outputFile
    Write-Host "Success! Data saved to $outputFile."
}

# --- Duplicate Audit ---
if ($findDupes) {
    Write-Host "`n--- Duplicate ID Audit ---"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "Cache file '$outputFile' not found. Cannot perform duplicate audit."
    } else {
        Write-Host "Analyzing '$outputFile' for duplicate IDs..."
        
        $data = Get-Content $outputFile -Raw | ConvertFrom-Json
        $duplicates = $data | Group-Object id | Where-Object { $_.Count -gt 1 }

        if ($duplicates) {
            Write-Host "Duplicate IDs found:"
            foreach ($dup in $duplicates) {
                "$($dup.Name) ($($dup.Count))"
            }
        } else {
            Write-Host "No duplicate IDs found."
        }
    }
}

# --- Inactive Audit ---
if ($findInactive) {
    Write-Host "`n--- Inactive Webcam Audit ---"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "Cache file '$outputFile' not found. Cannot perform inactive audit."
    } else {
        Write-Host "Analyzing '$outputFile' for inactive webcams..."
        
        $data = Get-Content $outputFile -Raw | ConvertFrom-Json
        $inactive = $data | Where-Object { $_.status -eq "Inactive" }

        if ($inactive) {
            Write-Host "Inactive webcams found:"
            foreach ($cam in $inactive) {
                "[$($cam.id)] $($cam.title)"
            }
            $inactive # Output to success stream
        } else {
            Write-Host "No inactive webcams found."
        }
    }
}

# --- Active Audit ---
if ($findActive) {
    Write-Host "`n--- Active Webcam Audit ---"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "Cache file '$outputFile' not found. Cannot perform active audit."
    } else {
        Write-Host "Analyzing '$outputFile' for active webcams..."
        
        $data = Get-Content $outputFile -Raw | ConvertFrom-Json
        $active = $data | Where-Object { $_.status -eq "Active" }

        if ($active) {
            Write-Host "Active webcams found:"
            foreach ($cam in $active) {
                "[$($cam.id)] $($cam.title)"
            }
            $active # Output to success stream
        } else {
            Write-Host "No active webcams found."
        }
    }
}

# --- Find By ID ---
if ($findByID) {
    Write-Host "`n--- Find Webcam By ID ---"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "Cache file '$outputFile' not found. Cannot perform ID search."
    } else {
        Write-Host "Searching '$outputFile' for ID: $findByID..."
        
        $data = Get-Content $outputFile -Raw | ConvertFrom-Json
        $record = $data | Where-Object { $_.id -eq $findByID }

        if ($record) {
            Write-Host "Found matching record:"
            $record
        } else {
            Write-Warning "No webcam found with ID: $findByID"
        }
    }
}

# --- Find By Title ---
if ($findTitle) {
    Write-Host "`n--- Find Webcams By Title ---"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "Cache file '$outputFile' not found. Cannot perform title search."
    } else {
        Write-Host "Searching '$outputFile' for title containing: $findTitle..."
        
        $data = Get-Content $outputFile -Raw | ConvertFrom-Json
        
        # Use -like with wildcard padding for case-insensitive substring match in PS 5.1
        # Escape any wildcards in the user input to ensure literal match
        $escapedSearch = [Management.Automation.WildcardPattern]::Escape($findTitle)
        $pattern = "*$escapedSearch*"
        
        $matches = $data | Where-Object { 
            $_.title -and ($_.title -like $pattern)
        }

        if ($matches) {
            Write-Host "Matching webcams found:"
            foreach ($cam in $matches) {
                "[$($cam.id)] $($cam.title)"
            }
            $matches # Output to success stream
        } else {
            Write-Warning "No webcams found with title containing: $findTitle"
        }
    }
}

# --- Find By Description ---
if ($findDescription) {
    Write-Host "`n--- Find Webcams By Description ---"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "Cache file '$outputFile' not found. Cannot perform description search."
    } else {
        Write-Host "Searching '$outputFile' for description containing: $findDescription..."
        
        $data = Get-Content $outputFile -Raw | ConvertFrom-Json
        
        # Use -like with wildcard padding for case-insensitive substring match in PS 5.1
        # Escape any wildcards in the user input to ensure literal match
        $escapedSearch = [Management.Automation.WildcardPattern]::Escape($findDescription)
        $pattern = "*$escapedSearch*"
        
        $matches = $data | Where-Object { 
            $_.description -and ($_.description -like $pattern)
        }

        if ($matches) {
            Write-Host "Matching webcams found:"
            foreach ($cam in $matches) {
                "[$($cam.id)] $($cam.title)"
            }
            $matches # Output to success stream
        } else {
            Write-Warning "No webcams found with description containing: $findDescription"
        }
    }
}

# --- Find Streaming Webcams ---
if ($findStreaming) {
    Write-Host "
--- Find Streaming Webcams ---"

    if (-not (Test-Path $outputFile)) {
        Write-Warning "Cache file '$outputFile' not found. Cannot perform streaming search."
    } else {
        Write-Host "Analyzing '$outputFile' for streaming webcams..."
        
        $data = Get-Content $outputFile -Raw | ConvertFrom-Json
        $streaming = $data | Where-Object { $_.isStreaming -eq $true }

        if ($streaming) {
            Write-Host "Streaming webcams found:"
            foreach ($cam in $streaming) {
                "[$($cam.id)] $($cam.title) - $($cam.url)"
            }
        } else {
            Write-Host "No streaming webcams found."
        }
    }
}
