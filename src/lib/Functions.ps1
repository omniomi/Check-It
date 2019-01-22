function CIConfig {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = 1)][scriptblock]$Config
    )
    $checkit.context.Peek().properties += $Config
}

function SendTeamsNotification {
    param(
        [object[]]
        $Results,

        [string]
        $FileName,

        [string]
        $Uri
    )

    $FailedResults = $Results | Where-Object {$_.Passed -eq $false}
    $Body = @{
        summary = 'New Check-It Notification'
        themeColor = $Teams.Color.TrimStart('#')
        sections = @(
            @{
                activityTitle = $FileName
                activitySubtitle = (Get-Date).ToString()
                activityImage = $Teams.Image
            }
        )
    }

    foreach ($Result in $FailedResults) {
        $Status = '[<b><font color="'+$Color.Status.Failed+'">'+$Result.Result+'</font></b>]'

        $Body.sections += @{
            title = $Status + ' ' + $Result.Name
            text = "`t" + $Result.FailureMessage
        }
    }

    $Body = ConvertTo-Json -Depth 4 $Body
    Invoke-RestMethod -uri $Uri -Method Post -body $Body -ContentType 'application/json' | Out-Null
}

function SendNotification {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    param(
        [object[]]
        $Results,

        [string]
        $FileName,

        [string[]]
        $Address
    )

    $FailedCount = ($Results | Where-Object {$_.Passed -eq $false}).Count
    if ($FailedCount -eq $Results.Count) {
        $Condition = 'Failed'
        $Priority = 'High'
    } elseif ($FailedCount -lt $Results.Count -and $FailedCount -ge 1) {
        $Condition = 'Partial'
        $Priority = 'High'
    } else {
        $Condition = 'Passed'
        $Priority = 'Low'
    }

    $UniqueDescribe = $Results | Sort-Object Describe -Unique | Select-Object -ExpandProperty Describe

    $Output = Get-Content $TemplateTop -Raw
    $Output = $Output -replace '\{file\}',$FileName.ToLower() -replace '\{title\}',$Title.ToUpper() `
                                                              -replace '\{server\}',$Env:COMPUTERNAME.ToLower() `
                                                              -replace '\{message\}',$IntroMessage `
                                                              -replace '\{PrimaryColor\}',$Color.Primary `
                                                              -replace '\{SecondaryColor\}',$Color.Secondary `
                                                              -replace '\{PrimaryFontColour\}',$Color.Text.Primary

    foreach ($Describe in $UniqueDescribe) {
        $Output += @"
        <table class=MsoNormalTable border=1 cellspacing=0 cellpadding=0 width="100%" style='width:100.0%;border-collapse:collapse;border:none'>
            <tr>
                <td width="100%" valign=top style='width:100.0%;border:none;border-left:solid $($Color.Primary) 4.5pt;background:$($Color.Primary);padding:0in 5.4pt 0in 5.4pt'>
                    <p class=MsoNormal>
                        <b>
                            <span style='font-size:16.0pt;color:$($Color.Text.Primary)'>$Describe</span>
                            <o:p></o:p>
                        </b>
                    </p>
                </td>
            </tr>
            <tr>
                <td width="100%" valign=top style='width:100.0%;border-top:none;border-left:solid $($Color.Primary) 4.5pt;border-bottom:solid $($Color.Primary) 2.25pt;border-right:none;padding:0in 5.4pt 0in 5.4pt'>
"@

        $UniqueContext = $Results | Where-Object { $_.Describe -eq $Describe } | Sort-Object Context -Unique | Select-Object -ExpandProperty Context

        foreach ($Context in $UniqueContext) {
            $Items = $Results | Where-Object { $_.Describe -eq $Describe -and $_.Context -eq $Context }

            $Output += @"
            <table class=MsoNormalTable border=1 cellspacing=0 cellpadding=0 style='border-collapse:collapse;border:none'>
                <tr>
                    <td width=1674 valign=top style='width:1255.3pt;border:none;border-left:solid $($Color.Secondary) 2.25pt;background:$($Color.Secondary);padding:0in 5.4pt 0in 5.4pt'>
                        <p class=MsoNormal>
                            <b><span style='font-size:12.0pt;color:white'><span style='color:$($Color.Text.Secondary)'>$Context</span></span></b>
                            <b>
                                <span style='color:white'>
                                    <o:p></o:p>
                                </span>
                            </b>
                        </p>
                    </td>
                </tr>
                <tr>
                    <td width="100%" valign=top style='width:100%;border:none;border-left:solid $($Color.Secondary) 2.25pt;padding:0in 5.4pt 0in 5.4pt'>
                        <table class=MsoNormalTable border=0 cellspacing=0 cellpadding=0 width="100%" style='width:100.0%;border-collapse:collapse'>
                            <tr>
                                <td width="30%" valign=top style='width:30%;border:none;border-left:solid $($Color.Tertiary) 1.5pt;background:$($Color.Tertiary);padding:0in 5.4pt 0in 5.4pt'>
                                    <p class=MsoNormal>
                                        <b>
                                            <span style='color:$($Color.Text.Tertiary)'>Name</span>
                                            <o:p></o:p>
                                        </b>
                                    </p>
                                </td>
                                <td width="10%" valign=top style='width:10%;background:$($Color.Tertiary);padding:0in 5.4pt 0in 5.4pt'>
                                    <p class=MsoNormal>
                                        <b>
                                            <span style='color:$($Color.Text.Tertiary)'>Result</span>
                                            <o:p></o:p>
                                        </b>
                                    </p>
                                </td>
                                <td valign=top width="60%" style='width:60%;background:$($Color.Tertiary);padding:0in 5.4pt 0in 5.4pt'>
                                    <p class=MsoNormal>
                                        <b>
                                            <span style='color:$($Color.Text.Tertiary)'>Message</span>
                                            <o:p></o:p>
                                        </b>
                                    </p>
                                </td>
                            </tr>
"@

            foreach ($Item in $Items) {
                switch ($Item.Result) {
                    'Passed' { $BackgroundColor = $Color.Status.Passed }
                    'Failed' { $BackgroundColor = $Color.Status.Failed}
                    default  { $BackgroundColor = $Color.Status.Other }
                }
                $Output += @"
                <tr>
                    <td width="30%" valign=top style='width:30%;border:none;border-left:solid $($Color.Tertiary) 1.5pt;padding:0in 5.4pt 0in 5.4pt'>
                        <p class=MsoNormal>
                            $($Item.Name)
                            <o:p></o:p>
                        </p>
                    </td>
                    <td width="10%" valign=top style='width:10%;padding:0in 5.4pt 0in 5.4pt;background:$BackgroundColor;'>
                        <p class=MsoNormal>
                            $($Item.Result)
                            <o:p></o:p>
                        </p>
                    </td>
                    <td width="60%" valign=top style='width:60%;padding:0in 5.4pt 0in 5.4pt'>
                        <p class=MsoNormal>
                            $($Item.FailureMessage)
                            <o:p></o:p>
                        </p>
                    </td>
                </tr>
"@
            }
            $Output += '</table></td></tr></table>'
        }
        $Output += '</td></tr></table><br>'
    }

    $Output += Get-Content $TemplateBottom -Raw

    $MessageSubject = "[$Condition] $Subject - $($FileName.ToLower())"

    $SmtpSplat = @{
        Body       = $Output
        BodyAsHtml = $true
        Subject    = $MessageSubject
        To         = $Address
        From       = $Smtp.From
        SmtpServer = $Smtp.Server
        Port       = $Smtp.Port
        Priority   = $Priority
    }

    if ($Smtp.Username) {
        $Password = ConvertTo-SecureString $Smtp.Password -AsPlainText -Force
        $Credential = [System.Management.Automation.PSCredential]::New($Smtp.Username,$Password)
        $SmtpSplat.Credential = $Credential
    }

    Send-MailMessage @SmtpSplat
}
