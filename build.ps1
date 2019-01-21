[cmdletbinding()]
param(
    [parameter()]
    [ValidateSet('Build','osFinish','Test')]
    [String]$Task = 'Test'
)

if ($Env:APPVEYOR_BUILD_VERSION) {
    $Version = $Env:APPVEYOR_BUILD_VERSION
} else {
    $Version = '1.0.0.x'
}

$OutDir       = "$PSScriptRoot\Release"
$ScriptName   = 'Check-It'
$ScriptOutDir = Join-Path $OutDir $ScriptName

if ($Task -eq 'osFinish') {
    $stagingDirectory = (Resolve-Path $env:APPVEYOR_BUILD_FOLDER).Path
    $releaseDirectory = Join-Path $env:APPVEYOR_BUILD_FOLDER '\Release\Check-It'
    $zipFile = Join-Path $stagingDirectory "Check-It-$($env:APPVEYOR_REPO_BRANCH)-$Version.zip"
    Add-Type -assemblyname System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($releaseDirectory, $zipFile)
    Write-Host $zipFile
    Push-AppveyorArtifact $zipFile
} elseif ($Task -eq 'Build') {
    if ($OutDir.Length -gt 3 -and (Test-Path -LiteralPath $OutDir)) {
        Get-ChildItem $OutDir | Remove-Item -Recurse -Force
    }
    else {
        Write-Verbose "'$OutDir' must be longer than 3 characters."
    }

    if (!(Test-Path -LiteralPath $OutDir)) {
        New-Item $OutDir -ItemType Directory > $null
    }
    else {
        Write-Verbose "Directory already exists '$OutDir'."
    }

    if (!(Test-Path -LiteralPath $ScriptOutDir)) {
        New-Item $ScriptOutDir -ItemType Directory > $null
    }
    else {
        Throw "Directory already exists '$ScriptOutDir'."
    }

    try {
        Copy-Item (Join-Path $PSScriptRoot 'src\*') -Destination $ScriptOutDir -Recurse > $null
    } catch {
        $PSItem.Throw($_)
    }
} elseif ($Task -eq 'Test') {
    Invoke-Expression -Command "$PSCommandPath Build"
    $Results = Invoke-Pester .\test\ -PassThru

    if ($Results.FailedCount -eq 0) {
        if (Get-Command Compress-Archive) {
            $ZipName = 'Check-It.zip'
            Compress-Archive -Path $ScriptOutDir -DestinationPath (Join-Path $OutDir $ZipName) -Force
        } else {
            "Compress-Archive command not found. Skipping."
            return
        }
    }
}
