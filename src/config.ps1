###############################################################################
# Customize these properties for your deployment.
###############################################################################

CIConfig {
    # --------------------------- Basic properties ----------------------------

    # Daily execution time - specifies at what time each day the .daily checks should run.
    # Specify the hour in 24 hour time. Checks will run on first execution after that hour.
    # Ie, if the task runs every hour at quarter-after and this is set to 8 the daily checks
    # will run at 8:15.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DailyRunTime = 8

    # Email template files
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TemplateTop    = "$PSScriptRoot\lib\template.top.html"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TemplateBottom = "$PSScriptRoot\lib\template.bottom.html"

    # Check files that should be ignored/skipped.
    # Specify the entire filename including the '.ps1'.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ExcludeChecks = @()

    # Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
    # This is typically used to write out test results so that they can be sent to a CI system.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFile = $null # NOT IMPLEMENTED


    # ---------------------------- Email Settings -----------------------------

    # Enable/disable email notifications.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $NotificationsEnabled = $true

    # Specify the title/logo for the message (appears in the body, top-left)
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Title = 'Check-It'

    # Specify the introduction text included at the top of every email message.
    # This text will appear above the first set of results.
    # HTML supported.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $IntroMessage = ''

    # Specify the subject for notification emails.
    # Will be prepended with "[Success]" or "[Failure]" depending on test results.
    # The name of the check file will similarly be appended to the end.
    # Ie, [Success]/[Failure] $Subject - <check filename>.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Subject = 'Check-It results'

    # SMTP Configuration for notifications.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Smtp = @{
        From      = 'noreply@example.com'
        Server    = '10.25.25.25'
        Port      = 25
        Username  = $null
        Password  = $null
    }

    # ---------------------------- Theme Settings -----------------------------

    # Set the colours used in the email notifications.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Color = @{
        # Main Theme Colours
        Primary       = '#0070C0' # Background Colour for Title and Pester->Description
        Secondary     = '#002060' # Background Colour for Pester->Context
        Tertiary      = '#D5DCE4' # Background Colour for Pester-It Header

        # Corresponding Text Colours
        Text          = @{
            Primary   = '#FFFFFF' # Text Colour for Title and Pester->Description
            Secondary = '#FFFFFF' # Text Colour for for Pester->Context
            Tertiary  = '#000000' # Text Colour for Pester-It Header
        }

        # Status Colours
        Status        = @{
            Failed    = '#ff9999' # Background Colour for Failed Tests
            Passed    = '#99ff99' # Background Colour for Passed Tests
            Other     = '#FFFFFF' # Background Colour for All Other Tests
        }
    }

    # Set the colours and image used in Microsoft Teams notifications.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Teams = @{
        # This color appears across the top of the notification.
        Color = '#D7000A'

        # Image appears as a 52x52 icon beside the notification.
        Image = 'https://i.imgur.com/vQXnnZa.png'
    }
}
