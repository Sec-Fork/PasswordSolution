﻿function Start-PasswordSolution {
    <#
    .SYNOPSIS
    Starts Password Expiry Notifications for the whole forest

    .DESCRIPTION
    Starts Password Expiry Notifications for the whole forest

    .PARAMETER ConfigurationDSL
    Parameter description

    .PARAMETER EmailParameters
    Parameters for Email. Uses Mailozaurr splatting behind the scenes, so it supports all options that Mailozaurr does.

    .PARAMETER OverwriteEmailProperty
    Property responsible for overwriting the default email field in Active Directory. Useful when the password notification has to go somewhere else than users email address.

    .PARAMETER UserSection
    Parameter description

    .PARAMETER ManagerSection
    Parameter description

    .PARAMETER SecuritySection
    Parameter description

    .PARAMETER AdminSection
    Parameter description

    .PARAMETER Rules
    Parameter description

    .PARAMETER TemplatePreExpiry
    Parameter description

    .PARAMETER TemplatePreExpirySubject
    Parameter description

    .PARAMETER TemplatePostExpiry
    Parameter description

    .PARAMETER TemplatePostExpirySubject
    Parameter description

    .PARAMETER TemplateManager
    Parameter description

    .PARAMETER TemplateManagerSubject
    Parameter description

    .PARAMETER TemplateSecurity
    Parameter description

    .PARAMETER TemplateSecuritySubject
    Parameter description

    .PARAMETER TemplateManagerNotCompliant
    Parameter description

    .PARAMETER TemplateManagerNotCompliantSubject
    Parameter description

    .PARAMETER TemplateAdmin
    Parameter description

    .PARAMETER TemplateAdminSubject
    Parameter description

    .PARAMETER Logging
    Parameter description

    .PARAMETER HTMLReports
    Parameter description

    .PARAMETER SearchPath
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'DSL')]
    param(
        [Parameter(ParameterSetName = 'DSL', Position = 0)][scriptblock] $ConfigurationDSL,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][System.Collections.IDictionary] $EmailParameters,
        [Parameter(ParameterSetName = 'Legacy')][string] $OverwriteEmailProperty,
        [Parameter(ParameterSetName = 'Legacy')][string] $OverwriteManagerProperty,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][System.Collections.IDictionary] $UserSection,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][System.Collections.IDictionary] $ManagerSection,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][System.Collections.IDictionary] $SecuritySection,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][System.Collections.IDictionary] $AdminSection,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][Array] $Rules,
        [Parameter(ParameterSetName = 'Legacy')][scriptblock] $TemplatePreExpiry,
        [Parameter(ParameterSetName = 'Legacy')][string] $TemplatePreExpirySubject,
        [Parameter(ParameterSetName = 'Legacy')][scriptblock] $TemplatePostExpiry,
        [Parameter(ParameterSetName = 'Legacy')][string] $TemplatePostExpirySubject,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][scriptblock] $TemplateManager,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][string] $TemplateManagerSubject,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][scriptblock] $TemplateSecurity,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][string] $TemplateSecuritySubject,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][scriptblock] $TemplateManagerNotCompliant,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][string] $TemplateManagerNotCompliantSubject,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][scriptblock] $TemplateAdmin,
        [Parameter(Mandatory, ParameterSetName = 'Legacy')][string] $TemplateAdminSubject,
        [Parameter(ParameterSetName = 'Legacy')][System.Collections.IDictionary] $Logging = @{},
        [Parameter(ParameterSetName = 'Legacy')][Array] $HTMLReports,
        [Parameter(ParameterSetName = 'Legacy')][string] $SearchPath
    )
    $TimeStart = Start-TimeLog
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Start-PasswordSolution' -RepositoryOwner 'evotecit' -RepositoryName 'PasswordSolution'

    Write-Color -Text '[i]', "[PasswordSolution] ", 'Version', ' [Informative] ', $Script:Reporting['Version'] -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

    $TodayDate = Get-Date
    $Today = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Set-LoggingCapabilities -LogPath $Logging.LogFile -LogMaximum $Logging.LogMaximum -ShowTime:$Logging.ShowTime -TimeFormat $Logging.TimeFormat
    # since the first entry didn't go to log file, this will
    Write-Color -Text '[i]', "[PasswordSolution] ", 'Version', ' [Informative] ', $Script:Reporting['Version'] -Color Yellow, DarkGray, Yellow, DarkGray, Magenta -NoConsoleOutput

    $Summary = [ordered] @{}
    $Summary['Notify'] = [ordered] @{}
    $Summary['NotifyManager'] = [ordered] @{}
    $Summary['NotifySecurity'] = [ordered] @{}
    $Summary['Rules'] = [ordered] @{}

    $AllSkipped = [ordered] @{}
    $Locations = [ordered] @{}

    # lets try to get configuration, and if not provided do some defaults
    $SplatPasswordConfiguration = [ordered] @{
        ConfigurationDSL                   = $ConfigurationDSL
        EmailParameters                    = $EmailParameters
        OverwriteEmailProperty             = $OverwriteEmailProperty
        OverwriteManagerProperty           = $OverwriteManagerProperty
        UserSection                        = $UserSection
        ManagerSection                     = $ManagerSection
        SecuritySection                    = $SecuritySection
        AdminSection                       = $AdminSection
        Rules                              = $Rules
        TemplatePreExpiry                  = $TemplatePreExpiry
        TemplatePreExpirySubject           = $TemplatePreExpirySubject
        TemplatePostExpiry                 = $TemplatePostExpiry
        TemplatePostExpirySubject          = $TemplatePostExpirySubject
        TemplateManager                    = $TemplateManager
        TemplateManagerSubject             = $TemplateManagerSubject
        TemplateSecurity                   = $TemplateSecurity
        TemplateSecuritySubject            = $TemplateSecuritySubject
        TemplateManagerNotCompliant        = $TemplateManagerNotCompliant
        TemplateManagerNotCompliantSubject = $TemplateManagerNotCompliantSubject
        TemplateAdmin                      = $TemplateAdmin
        TemplateAdminSubject               = $TemplateAdminSubject
        Logging                            = $Logging
        HTMLReports                        = $HTMLReports
        SearchPath                         = $SearchPath
    }
    $InitialVariables = Set-PasswordConfiguration @SplatPasswordConfiguration
    if (-not $InitialVariables) {
        return
    }

    $EmailParameters = $InitialVariables.EmailParameters
    $OverwriteEmailProperty = $InitialVariables.OverwriteEmailProperty
    $OverwriteManagerProperty = $InitialVariables.OverwriteManagerProperty
    $UserSection = $InitialVariables.UserSection
    $ManagerSection = $InitialVariables.ManagerSection
    $SecuritySection = $InitialVariables.SecuritySection
    $AdminSection = $InitialVariables.AdminSection
    $Rules = $InitialVariables.Rules
    $TemplatePreExpiry = $InitialVariables.TemplatePreExpiry
    $TemplatePreExpirySubject = $InitialVariables.TemplatePreExpirySubject
    $TemplatePostExpiry = $InitialVariables.TemplatePostExpiry
    $TemplatePostExpirySubject = $InitialVariables.TemplatePostExpirySubject
    $TemplateManager = $InitialVariables.TemplateManager
    $TemplateManagerSubject = $InitialVariables.TemplateManagerSubject
    $TemplateSecurity = $InitialVariables.TemplateSecurity
    $TemplateSecuritySubject = $InitialVariables.TemplateSecuritySubject
    $TemplateManagerNotCompliant = $InitialVariables.TemplateManagerNotCompliant
    $TemplateManagerNotCompliantSubject = $InitialVariables.TemplateManagerNotCompliantSubject
    $TemplateAdmin = $InitialVariables.TemplateAdmin
    $TemplateAdminSubject = $InitialVariables.TemplateAdminSubject
    $Logging = $InitialVariables.Logging
    $HTMLReports = $InitialVariables.HTMLReports
    $SearchPath = $InitialVariables.SearchPath

    # this is to get properties from rules to be used in building up user output
    [Array] $ExtendedProperties = foreach ($Rule in $Rules ) {
        if ($Rule.OverwriteEmailProperty) {
            $Rule.OverwriteEmailProperty
        }
        if ($Rule.OverwriteManagerProperty) {
            $Rule.OverwriteManagerProperty
        }
    }

    $SummarySearch = Import-SearchInformation -SearchPath $SearchPath

    Write-Color -Text "[i]", " Starting process to find expiring users" -Color Yellow, White, Green, White, Green, White, Green, White
    $CachedUsers = Find-Password -AsHashTable -OverwriteEmailProperty $OverwriteEmailProperty -RulesProperties $ExtendedProperties -OverwriteManagerProperty $OverwriteManagerProperty

    if ($Rules.Count -eq 0) {
        Write-Color -Text "[e]", " No rules found. Please add some rules to configuration" -Color Yellow, White, Red
        return
    }

    foreach ($Rule in $Rules) {
        $SplatProcessingRule = [ordered] @{
            Rule        = $Rule
            Summary     = $Summary
            CachedUsers = $CachedUsers
            AllSkipped  = $AllSkipped
            Locations   = $Locations
            Loggin      = $Logging
            TodayDate   = $TodayDate
        }
        Invoke-PasswordRuleProcessing @SplatProcessingRule
    }

    $SplatUserNotifications = [ordered] @{
        UserSection               = $UserSection
        Summary                   = $Summary
        Logging                   = $Logging
        TemplatePreExpiry         = $TemplatePreExpiry
        TemplatePreExpirySubject  = $TemplatePreExpirySubject
        TemplatePostExpiry        = $TemplatePostExpiry
        TemplatePostExpirySubject = $TemplatePostExpirySubject
        EmailParameter            = $EmailParameters
    }

    [Array] $SummaryUsersEmails = Send-PasswordUserNofifications @SplatUserNotifications

    $SplatManagerNotifications = [ordered] @{
        ManagerSection                     = $ManagerSection
        Summary                            = $Summary
        CachedUsers                        = $CachedUsers
        TemplateManager                    = $TemplateManager
        TemplateManagerSubject             = $TemplateManagerSubject
        TemplateManagerNotCompliant        = $TemplateManagerNotCompliant
        TemplateManagerNotCompliantSubject = $TemplateManagerNotCompliantSubject
        EmailParameters                    = $EmailParameters
        Loggin                             = $Logging
    }
    [Array] $SummaryManagersEmails = Send-PasswordManagerNofifications @SplatManagerNotifications

    $SplatSecurityNotifications = [ordered] @{
        SecuritySection         = $SecuritySection
        Summary                 = $Summary
        TemplateSecurity        = $TemplateSecurity
        TemplateSecuritySubject = $TemplateSecuritySubject
        Logging                 = $Logging
    }
    [Array] $SummaryEscalationEmails = Send-PasswordSecurityNotifications @SplatSecurityNotifications

    $TimeEnd = Stop-TimeLog -Time $TimeStart -Option OneLiner

    Export-SearchInformation -SearchPath $SearchPath -SummarySearch $SummarySearch -Today $Today -SummaryUsersEmails $SummaryUsersEmails -SummaryManagersEmails $SummaryManagersEmails -SummaryEscalationEmails $SummaryEscalationEmails

    $HtmlAttachments = [System.Collections.Generic.List[string]]::new()

    foreach ($Report in $HTMLReports) {
        if ($Report.Enable) {
            $ReportSettings = @{
                Report                  = $Report
                EmailParameters         = $EmailParameters
                Logging                 = $Logging
                #FilePath                = $FilePath
                SearchPath              = $SearchPath
                Rules                   = $Rules
                UserSection             = $UserSection
                ManagerSection          = $ManagerSection
                SecuritySection         = $SecuritySection
                AdminSection            = $AdminSection
                CachedUsers             = $CachedUsers
                Summary                 = $Summary
                SummaryUsersEmails      = $SummaryUsersEmails
                SummaryManagersEmails   = $SummaryManagersEmails
                SummaryEscalationEmails = $SummaryEscalationEmails
                SummarySearch           = $SummarySearch
                Locations               = $Locations
                AllSkipped              = $AllSkipped
            }
            New-HTMLReport @ReportSettings

            if ($Report.AttachToEmail) {
                if (Test-Path -LiteralPath $Report.FilePath) {
                    $HtmlAttachments.Add($Report.FilePath)
                } else {
                    Write-Color -Text "[w] HTML report ", $Report.FilePath, " does not exist! Probably a temporary path was used. " -Color DarkYellow, Red, DarkYellow
                }
            }
        }
    }

    $AdminSplat = [ordered] @{
        AdminSection         = $AdminSection
        TemplateAdmin        = $TemplateAdmin
        TemplateAdminSubject = $TemplateAdminSubject
        TimeEnd              = $TimeEnd
        EmailParameters      = $EmailParameters
        HtmlAttachment       = $HtmlAttachments
    }
    Send-PasswordAdminNotifications @AdminSplat
}