#Requires -Modules Pester
<#
.SYNOPSIS
    Runs Pester tests and sends the results as an email and/or Teams notification.
.DESCRIPTION
    Runs one or more Pester test files found in a directory. Each file containing pester
    tests is checked for special attributes that tell the script where to send alerts about
    the results.
#>
[cmdletbinding()]
param(
    # Path to Pester test files. Default: .\Checks\
    [parameter()]
    [ValidatePathExists()]
    [string]$Path = (Join-Path $PSScriptRoot 'Checks'),

    # Pass -Show parameter options to Invoke-Pester.
    [parameter()]
    [ValidateSet('all','none','failed','passed','skipped','summary','pending','inconclusive','header','fails','describe','context')]
    [string[]]$Show = 'none',

    # Do not send email or Teams notifications. Can be set permanently in .\config.ps1
    [parameter()]
    [switch]$SuppressNotifications
)

###############################################################################
# Load Dependencies
###############################################################################

$DependencyPath = Join-Path $PSScriptRoot 'lib'
$Dependencies   = @(Get-ChildItem -Path $DependencyPath -Filter *.ps1 -Recurse)

foreach ($Dependency in $Dependencies) {
    try {
       Write-Verbose "Loading Dependency $($Dependency.Name)"
        . $Dependency.FullName
    }
    catch {
       $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

###############################################################################
# Load Configuration
###############################################################################
$script:checkit = @{}
$checkit.context = new-object system.collections.stack
$checkit.context.push(@{
    "properties" = @();
})

try {
    Write-Verbose "Loading Configuration"
     . (Get-Item (Join-Path $PSScriptRoot 'config.ps1') | Select-Object -ExpandProperty FullName)
} catch {
    $PSCmdlet.ThrowTerminatingError($PSItem)
}

foreach ($Block in $checkit.context.Peek().properties) {
    . $Block
}

###############################################################################
# Run Tests
###############################################################################

$CheckFiles = @(Get-ChildItem $Path -Exclude $ExcludeChecks -Filter *.ps1 -Recurse)

foreach ($Check in $CheckFiles) {
    Write-Verbose "Running checks in $($Check.Name)"
    # Pull notification attributes from file
    $Notify      = Get-Item $Check.FullName |
                     Get-Command { $_.FullName } |
                     Select-Object @{ n = 'opts' ; e = { $_.ScriptBlock.Attributes.Where{ $_.TypeID.Name -eq 'CINotifications' } } }
    $TeamsNotify = Get-Item $Check.FullName |
                     Get-Command { $_.FullName } |
                     Select-Object @{ n = 'opts' ; e = { $_.ScriptBlock.Attributes.Where{ $_.TypeID.Name -eq 'CITeamsNotifications' } } }

    # Run tests
    $Results = Invoke-Pester $Check.FullName -PassThru -Show $Show
    Write-Verbose "... Pester Failed count: $($Results.FailedCount)"

    # Send notifications
    if (-not($NotificationsEnabled) -or $SuppressNotifications) {
        Write-Verbose "... Notifications suppressed. Skipping."
        break
    }

    ## Email notifications
    if ($Notify.opts.Address) {
        if ($Results.FailedCount -eq 0 -and -not($Notify.opts.SendOnSuccess)) {
            continue
        } else {
            if ($Notify.opts.SendOnSuccess -and $Notify.opts.Address -eq $Notify.opts.SuccessAddress) {
                $SendTo = $Notify.opts.Address
            } elseif ($Notify.opts.SendOnSuccess -and $Notify.opts.Address -ne $Notify.opts.SuccessAddress) {
                if ($Results.FailedCount -ge 1) {
                    $SendTo = @($Notify.opts.Address,$Notify.opts.SuccessAddress)
                } else {
                    $SendTo = $Notify.opts.SuccessAddress
                }
            } elseif (-not($Notify.opts.SendOnSuccess) -and $Results.FailedCount -ge 1) {
                $SendTo = $Notify.opts.Address
            }

            SendNotification $Results.TestResult $Check.Name $SendTo
        }
    }

    ## Teams notifications
    if ($TeamsNotify.opts.Uri -and $Results.FailedCount -ge 1) {
        SendTeamsNotification $Results.TestResult $Check.Name $TeamsNotify.opts.Uri
    }
}
