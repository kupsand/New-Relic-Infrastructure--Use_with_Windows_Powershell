<#
.SYNOPSIS
    This Powershell script can be used to Install, Update, or Remove the New Relic Infrastructure Agent. -by Kevin Downs http://linkedin.com/in/kupsand

.DESCRIPTION
    All configuration options are available with this script. However, for a quick installation of the agent,
    only the License Key is required. While only three Custom Attributes are available with this script, you
    may edit the configuraiton file to include more.

.PARAMETER action
    Default is set to 'Install'
    (Required) Install, Update, or Remove.
    Note: Update only updates the Infrastructure agent, it doesn't update or change the agent configuration.

.PARAMETER licenseKey
    (Required) This is a mandatory parameter and is required for ALL actions.
    Usage: ./WindowsNRI_script.ps1 -licenseKey [YOUR_LICENSE_KEY]

.PARAMETER agentFileLocation
    (Optional) Only use if you need to install the agent from a non-internet connected instance.
    Examples: c:\\temp\\newrelic-infra.msi or https://s3.us-east-2.amazonaws.com/[mybucket]/newrelic-infra.repo

.PARAMETER displayName
    (Optional) Override the auto-generated hostname for reporting.
    This is useful when you have multiple hosts with the same name, since Infrastructure uses the hostname as the unique identifier for each host.    

.PARAMETER proxy
    (Optional) Your system may have firewall rules that require the agent to use a proxy to communicate with New Relic.
    If so, set the proxy URL in the form https://user:password@hostname:port.
    Can be HTTP or HTTPS.

.PARAMETER verboseLogging
    Default is set to '0'.
    (Optional) When set to 1, enables verbose logging for the agent.
    This is useful when troubleshooting the agent.
    When verbose logging is not set to 1, it defaults to off. 
    See also log_file to customize the log file location.

.PARAMETER logFile
    (Optional) To log to another location, provide a full path and file name.

.PARAMETER logToStdout
    Default is set to 'true'.
    (Optional) When this option is true or not explicitly set, the agent logs to the console,
    which is typically configured to write to system log files.
    If you have a log file set through the log_file option, the agent writes to both the
    specified file and the console when log_to_stdout is true or not explicitly set.
    Setting this option to false restricts output to the specified file only.",

.PARAMETER customAttributeOneName
    (Optional) A custom attributes is used to annotate the data from this agent instance.
    Example: environment
    Note on Custom Attributes:
    In order to use Custom Attributes Two or Three - Custom Attribute One must be used.

.PARAMETER customAttributeOneValue
    (Optional) A custom attributes is used to annotate the data from this agent instance.
    Example: production

.PARAMETER customAttributeTwoName
    (Optional) A custom attributes is used to annotate the data from this agent instance.
    Example: service

.PARAMETER customAttributeTwoValue
    (Optional) A custom attributes is used to annotate the data from this agent instance.
    Example: login service

.PARAMETER customAttributeThreeName
    (Optional) A custom attributes is used to annotate the data from this agent instance.
    Example: team

.PARAMETER customAttributeThreeValue
    (Optional) A custom attributes is used to annotate the data from this agent instance.
    Example: alpha-team

.EXAMPLE
    ./WindowsNRI_script.ps1 -licenseKey [YOUR_LICENSE_KEY] -displayName ProdServer1 -customAttributeOneName Application -customAttributeOneValue AwesomeApp

.NOTES
    Creation Date: Oct 21st, 2017
    Author: Kevin Downs
    LinkedIn: http://linkedin.com/in/kupsand
    
.LINK
    https://docs.newrelic.com/docs/infrastructure/new-relic-infrastructure/installation/install-infrastructure-windows-server
#>


# Command line parameters
param (
    [ValidateSet('Install', 'Update', 'Remove')]
    [string]$action = "Install",
    [Parameter(Mandatory = $true)]
    [string]$licenseKey, # For faster installation,change this line to: [string]$licenseKey = "[YOUR_LICENSE_KEY]",
    [string]$agentFileLocation,
    [string]$displayName,
    [string]$proxy,
    [string]$verboseLogging = "0",
    [string]$logFile,
    [string]$logToStdout = "true",
    [string]$customAttributeOneName,
    [string]$customAttributeOneValue,
    [string]$customAttributeTwoName,
    [string]$customAttributeTwoValue,
    [string]$customAttributeThreeName,
    [string]$customAttributeThreeValue
)

# Set the paths
$nri_config_file = "C:\Program Files\New Relic\newrelic-infra\newrelic-infra.yml"
$nri_install_file = "c:\Users\Administrator\Documents\newrelic-infra.msi"
$nri_download_file = "https://download.newrelic.com/infrastructure_agent/windows/newrelic-infra.msi"

# Get the New Relic Infrastructure agent
if ( $action -eq "Install" )
{
    if ( $agentFileLocation -ne "" )
    {
        $msiFileName = $agentFileLocation
        if ( $msiFileName.Substring(0,4) -eq "http")
        {
            wget $msiFileName -OutFile $nri_install_file
        }
        Else
        {
            # Assuming drive/path i.e. D:/path/file
            Copy-Item $msiFileName $nri_install_file
        }
    }
    Else
    {
        wget $nri_download_file -OutFile $nri_install_file
    }

    # Install the agent
    msiexec.exe /qn /i $nri_install_file

    # Need a little bit of time to allow the agent/directory/service to install - 5 seconds
    Start-Sleep -s 5

    # Set up the configuration file and add the License Key
    echo "license_key: $licenseKey" | Out-File -FilePath $nri_config_file -Encoding ASCII

    # If entered, add the Display name
    if ( $displayName -ne "" )
    {
        echo "display_name: $displayName" | Out-File -FilePath $nri_config_file -Encoding ASCII -Append
    }

    # If entered, set the Proxy
    if ( $proxy -ne "" )
    {
        echo "proxy: $proxy" | Out-File -FilePath $nri_config_file -Encoding ASCII -Append
    }

    # Set Verbose
    echo "verbose: $verboseLogging" | Out-File -FilePath $nri_config_file -Encoding ASCII -Append

    # If entered, set the Log File
    if ( $logFile -ne "" )
    {
        echo "log_file: $logFile" | Out-File -FilePath $nri_config_file -Encoding ASCII -Append
    }

    # Set log to stdout
    echo "log_to_stdout: $logToStdout" | Out-File -FilePath $nri_config_file -Encoding ASCII -Append

    # If entered, add custom attribute(s)
    if ( $customAttributeOneName -ne "" )
    {
        if ( $customAttributeOneValue -ne "" )
        {
            echo "custom_attributes:" | Out-File -FilePath $nri_config_file -Encoding ASCII -Append
            echo $( "  $customAttributeOneName" + ": " + "$customAttributeOneValue" ) | Out-File -FilePath $nri_config_file -Encoding ASCII -Append
        }
    }

    if ( $customAttributeOneName -ne "" )
    {
        if ( $customAttributeTwoName -ne "" )
        {
            if ( $customAttributeTwoValue -ne "" ) 
            {
                echo $( "  $customAttributeTwoName" + ": " + "$customAttributeTwoValue" ) | Out-File -FilePath $nri_config_file -Encoding ASCII -Append
            }
        }
    }

    if ( $customAttributeOneName -ne "" )
    {
        if ( $customAttributeThreeName -ne "" )
        {
            if ( $customAttributeThreeValue -ne "" )
            {
                echo $( "  $customAttributeThreeName" + ": " + "$customAttributeThreeValue" ) | Out-File -FilePath $nri_config_file -Encoding ASCII -Append
            }
        }
    }

    # Start the agent service
    net start newrelic-infra
}
ElseIf ( $action -eq "Update" )
{
    # Download the latest New Relic Infrastructure agent
    if ( $agentFileLocation -ne "" )
    {
        $msiFileName = $agentFileLocation
        if ( $msiFileName.Substring(0,4) -eq "http" )
        {
            wget $msiFileName -OutFile $nri_install_file
        }
        Else
        {
            Copy-Item $msiFileName $nri_install_file
        }
    }
    Else
    {
        wget $nri_download_file -OutFile $nri_install_file
    }

    # Install the agent
    msiexec.exe /qn /i $nri_install_file
}
Else
{
    # Remove the New Relic Infrastructure agent

    # Stop the agent service
    net stop newrelic-infra

    # Remove the New Relic registry entry
    Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\newrelic-infra"

    # Delete the New Relic directory under Program Files
    Remove-Item -Recurse -Force "C:\Program Files\New Relic\"
}
