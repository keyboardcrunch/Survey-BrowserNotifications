<#
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
#>

Param (
    [Alias('IPAddress','Server')]
    [PSObject]$Computername = $Env:Computername,
    [Int]$Throttle = 10,
    [String]$DataDir = ".\",
    [ValidateSet('Firefox','Chrome','All')]
    [String]$Browser = "All"
)

$NotificationSubsSurvey = [System.IO.Path]::Combine($DataDir, "BrowserNotifications-Survey.csv")

# Inventory script to be invoked
$InventoryScript = {
    Param (
        [ValidateSet('Firefox','Chrome','All')]
        [String]$Browser = "All"
    )

    $SubscriptionList = @()
    $Computer = $($env:COMPUTERNAME)
    $SkipFolders = ("Public", "Default")
    $UserFolders = Get-ChildItem -Path "C:\Users\" -Exclude $SkipFolders

    Function FirefoxSurvey {
        $SubscriptionList = @()
        ForEach ($User in $UserFolders) {
            $Subscriptions = Get-ChildItem -Path "$($User)\AppData\Roaming\Mozilla\Firefox\Profiles" -Recurse -Filter notificationstore.json -Force -ErrorAction SilentlyContinue
            Foreach ($Sub in $subscriptions) {
                $Sites = Get-Content $Sub.FullName | ConvertFrom-Json
                $Sites = $Sites
                If (!([String]::IsNullOrEmpty($Sites))) {
                    $newRow = [PSCustomObject] @{
                        Computer = $Computer
                        User = $($User.Name)
                        Browser = "FireFox"
                        Subscription = $Sites
                    }
                    $SubscriptionList += $newRow
                }
            }
        }
        Return $SubscriptionList
    }

    Function ChromeSurvey {
        ForEach ($User in $UserFolders) {
            $Preferences = Get-ChildItem -Path "$($User)\AppData\Local\Google\Chrome\User Data\" -Recurse -Filter Preferences -Force -ErrorAction SilentlyContinue
            Foreach ($Pref in $Preferences) {
                $Data = Get-Content $Pref.FullName | ConvertFrom-Json
                $Sites = $Data.gcm.push_messaging_application_id_map
                If (!([String]::IsNullOrEmpty($Sites))) {
                    $newRow = [PSCustomObject] @{
                        Computer = $Computer
                        User = $($User.Name)
                        Browser = "Chrome"
                        Subscription = $Sites
                    }
                    $SubscriptionList += $newRow
                }
            }
        }
        Return $SubscriptionList
    }

    Switch ($Browser) {
        "Firefox" { $SubscriptionList += FirefoxSurvey }
        "Chrome" { $SubscriptionList += ChromeSurvey }
        "All" { 
            $SubscriptionList += FirefoxSurvey
            $SubscriptionList += ChromeSurvey
        }
    }
    Return $SubscriptionList | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1
}

Write-Host "Running inventory on $($Computername.Count) machines..." -ForegroundColor Yellow
Invoke-Command -ComputerName $Computername -ScriptBlock $InventoryScript -ArgumentList $Browser -ThrottleLimit $Throttle -ErrorAction SilentlyContinue -OutVariable Inventory

If ($DataDir) {
    $Inventory | ConvertFrom-Csv -Header Computer, User, Browser, Subscription | Export-Csv $NotificationSubsSurvey -NoClobber -NoTypeInformation -Force -Append
}
Write-Host "Completed." -ForegroundColor Green
