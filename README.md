# Check-It - A daily check list runner.

![Example Notification](https://i.imgur.com/Uk7yN2q.png "Example Notification")

Check-It is an email notification wrapper for [Pester](https://github.com/pester/Pester/) tests in PowerShell. The goal behind Check-It is to make it easy to write infrastructure or configuration checks in Pester and have the results emailed to you or a team on a schedule.

|Master   |  Development
|:------:|:------:
|[![Build status](https://ci.appveyor.com/api/projects/status/github/omniomi/check-it?branch=master&svg=true)](https://ci.appveyor.com/project/omniomi/check-it/branch/master)|[![Build status](https://ci.appveyor.com/api/projects/status/github/omniomi/check-it?branch=develop&svg=true)](https://ci.appveyor.com/project/omniomi/check-it/branch/develop)

## Pester

Pester is a test framework for PowerShell. It provides a language that allows you to define test cases, and the Invoke-Pester cmdlet to execute these tests and report the results.

A simple test might look like this:

```PowerShell
Describe "My Example Tests" {
    It "Is always true" {
        $true | Should -be $true
    }

    It "Is always false" {
        $false | Should -be $false
    }
}
```

When an assertion fails, for example `$true | Should -be $false` the test is reported as failed.

* For more information on writing Pester tests: https://github.com/pester/Pester/wiki

## Notifications

In order to make Pester useful for automated infrastructure and configuration checking a way to be alerted to failed tests was required. Check-It provides a way to specify who should be notified about the results of a particular set of checks and generates emails accordingly.

### Configuration

There are multiple options in [config.ps1](src/config.ps1) related to notifications such as SMTP server options, subject text, message text, and so on. Before scheduling Check-It make sure your configuration is correct.

### Specifying Recipients

Check-It provides a unique attribute that when placed at the top of a file containing Pester tests tells Check-It where and when to send notifications:

```PowerShell
[CINotifications('admins@example.com',1,'omni@example.com')]
param()
```

_Note: the `param()` is necessary._

The three parameters of the attribute are `Address[]`, `SendOnSuccess`, and `SuccessAddress[]`. The first address or list of addresses is where failure notifications are sent, the bool for `SendOnSuccess` is whether or not notifications should be generated when there are no failures, and the final address or list of addresses are optional recipients for success notifications.

If you enable `SendOnSuccess` but do not specify `SuccessAddress[]` successful results will be sent to `Address[]` instead:

```PowerShell
[CINotifications('admins@example.com',1)]
param()
```

will result in an email being sent to admins@example.com every time the script runs whether there is a failure or not.

By default you likely want to disable success notifications in order to avoid [alert fatigue](https://en.wikipedia.org/wiki/Alarm_fatigue):

```PowerShell
[CINotifications('admins@example.com',0)]
param()
```

### Microsoft Teams

![Example Notification](https://i.imgur.com/kmtYTDE.png "Example Notification")

NOTE: Teams notifications are only sent on failure and there is no SendOnSuccess option.

In order to send Microsoft Teams notifications you will need to add a webhook to your Teams channel and add the following attribute to your check file:

```PowerShell
[CITeamsNotifications('webhook url here')]
```

There is configuration in [config.ps1](src/config.ps1) for the color used across the top of the notification and the icon included in the message.

#### Multiple Recipients

Both `Address[]` and `SuccessAddress[]` accept a list of addresses if you have multiple recipients not in a distribution group:

```PowerShell
[CINotifications(@('admins@example.com','netadmins@example.com'),0)]
param()
```

## Scheduling

It is only necessary to create a single Scheduled Task or job. Schedule the execution of [RunChecks.ps1](src/RunChecks.ps1) and it will automatically iterate through all of the checks on each run. When adding a new check file there is no need to modify the task.

**Task schedule:** The task should be scheduled to run every hour forever. Checks in .daily will be executed during the first run after the daily run time config hour (default 8AM) while the .hourly checks will execute on every run. (See config file)

### Disabling a Check

In [config.ps1](src/config.ps1) you can add a check file to `$ExcludeChecks` if you want it to be ignored.
