#Requires -Modules Pester
###############################################################################
# Check-It ~ daily/hourly check list runner.
#
# This script is the entry point and can be scheduled in Task Scheduler or
# a CI tool like TeamCity without parameters.
#
# Please make all changes in the included config.ps1
#
param(
    [parameter()]
    [ValidateSet('all','none','failed','passed','skipped','summary','pending','inconclusive','header','fails','describe','context')]
    [string[]]$Show = 'none',

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
 }
 catch {
    $PSCmdlet.ThrowTerminatingError($PSItem)
 }

foreach ($Block in $checkit.context.Peek().properties) {
    . $Block
}

###############################################################################
# Run Tests
###############################################################################

$CheckFiles = @(Get-ChildItem "$PSScriptRoot\Checks.hourly" -Exclude $ExcludeChecks -Filter *.ps1 -Recurse)
if ((Get-Date).Hour -eq $DailyRunTime) {
    $CheckFiles += @(Get-ChildItem "$PSScriptRoot\Checks.daily" -Exclude $ExcludeChecks -Filter *.ps1 -Recurse)
}

foreach ($Check in $CheckFiles) {
    # Pull attributes from file
    $Notify      = Get-Item $Check.FullName |
                     Get-Command { $_.FullName } |
                     Select-Object @{ n = 'opts' ; e = { $_.ScriptBlock.Attributes.Where{ $_.TypeID.Name -eq 'CINotifications' } } }
    $TeamsNotify = Get-Item $Check.FullName |
                     Get-Command { $_.FullName } |
                     Select-Object @{ n = 'opts' ; e = { $_.ScriptBlock.Attributes.Where{ $_.TypeID.Name -eq 'CITeamsNotifications' } } }

    # Run tests
    $Results = Invoke-Pester $Check.FullName -PassThru -Show $Show

    # Send notifications
    if ($Results.FailedCount -eq 0 -and $Notify.opts.SendOnSuccess -eq 0) {
        continue
    } elseif ($NotificationsEnabled -eq $false -or -not($Notify.opts.Address)) {
        continue
    } else {
        if ($Notify.opts.SendOnSuccess -eq 1 -and $Notify.opts.Address -eq $Notify.opts.SuccessAddress) {
            $SendTo = $Notify.opts.Address
        } elseif ($Notify.opts.SendOnSuccess -eq 1 -and $Notify.opts.Address -ne $Notify.opts.SuccessAddress) {
            if ($Results.FailedCount -ge 1) {
                $SendTo = @($Notify.opts.Address,$Notify.opts.SuccessAddress)
            } else {
                $SendTo = $Notify.opts.SuccessAddress
            }
        } elseif ($Notify.opts.SendOnSuccess -eq 0 -and $Results.FailedCount -ge 1) {
            $SendTo = $Notify.opts.Address
        }

        if (-not($SuppressNotifications)) {
            SendNotification $Results.TestResult $Check.Name $SendTo
        }
    }
    if ($TeamsNotify.opts.Uri -and $Results.FailedCount -ge 1 -and -not($SuppressNotifications)) {
        SendTeamsNotification $Results.TestResult $Check.Name $TeamsNotify.opts.Uri
    }
}
