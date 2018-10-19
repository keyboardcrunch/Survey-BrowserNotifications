# Survey-BrowserNotifications

    .SYNOPSIS
        Runs a threaded survey of web push notifications subscribed to within Firefox and Chrome.

    .DESCRIPTION
        BrowserNotifications will search all profiles and users for browsers with web push notification subscriptions and output that data to a csv file.

    .PARAMETER Computername
        The target or targets to be surveyed.

    .PARAMETER Throttle
        The number of jobs for the survey to use. 10 is default.

    .PARAMETER DataDir
        Optional. The path for all saved data to be written. Defaults to .\ if left empty.

    .PARAMETER Browser
        The browser/s to target. Options are Firefox, Chrome or All.

    .NOTES
        Name: Survey-BrowserNotifications
        Author: keyboardcrunch
        Date Created: 19/10/18
    .EXAMPLE
        Survey-BrowserNotifications -Computername $(Get-Content .\Data\ChromeInstalled.txt) -Browser Chrome -Throttle 25

        Description
        -----------
        Runs a survey of web push notification subscriptions in Google Chrome on all machines listed within ChromeInstalled.txt using job throttle 
        for the scan. 

    .EXAMPLE
        Survey-BrowserNotifications -Computername $(Get-Content .\Data\ChromeInstalled.txt) -DataDir "\\NetworkShare\Extensions\"

        Description
        -----------
        Runs a survey of web push notification subscriptions in Google Chrome on all machines listed within ChromeInstalled.txt
        and saves data to \\NetworkShare\Extensions\BrowserNotification-Survey.csv. 
        Default 10 threads.
