

$Server = '192.168.0.28'
$User = 'root'
$Password = 'Password01'

$NTPServers = @('0.fr.pool.ntp.org','1.fr.pool.ntp.org','ntp.unice.fr')
$NTPRunning = $true
$NTPPolicy = "on"

$SyslogServer = "syslog.exemple.com"
$SyslogRunning = $true
$SyslogPolicy = "on"
$VMHostFirewallException = $true

$SSHRunning = $true
$SSHPolicy = "on"
$SSHSuppressShellWarning = 1 # 0 or 1

$DNSAddress = @('212.27.40.241', '212.27.40.240')
$DomainName = 'exemple.com'
$SearchDomain = 'exemple.com'

#Import PowerCLI Snapin
Try {
  Add-PsSnapin VMware.VimAutomation.Core -ErrorAction "SilentlyContinue"
}
Catch {
  Write-Debug "Error while loading PowerCLI: $($_.Exception.Message)"
  exit
}

$VIServer = Connect-VIServer -Server $Server -User $User -Password $Password
$VMHosts = Get-VMHost

#NTP Configuration
Describe "Hosts NTP configuration" {
  Foreach ($VMHost in $VMHosts)
  {
    Context "VMHost $($VMHost.Name)" {
      $VMHostNtpServer = Get-VMHostNtpServer
      Foreach ($NTPServer in $NTPServers) {
        It "Has a NTP Server set to $NTPServer" {
          $VMHostNtpServer -match $NTPServer | Should Be $true
        }
      }

      $NTPService = $VMHost | Get-VMHostService | where{$_.Key -eq "ntpd"}
      It "Has the NTP service set to $NTPRunning" {
        $NTPService.Running | Should Be $NTPRunning
      }

      It "Has the NTP policy set to $NTPPolicy" {
        $NTPService.Policy | Should Be $NTPPolicy
      }
    }
  }
}

#Syslog Configuration
Describe "Hosts syslog configuration" {
  Foreach ($VMHost in $VMHosts)
  {
    Context "VMHost $($VMHost.Name)" {

      It "Has the advanced value Syslog.global.logHost set to $SyslogServer" {
        ($VMHost | Get-AdvancedSetting -Name 'Syslog.global.logHost').Value | Should Be $SyslogServer
      }

      $SyslogService = $VMHost | Get-VMHostService | where{$_.Key -eq "syslog"}

      It "Has the Syslog service set to $SyslogRunning" -Skip {
        $SyslogService.Running | Should Be $SyslogRunning
      }

      It "Has the Syslog policy set to $SyslogPolicy" -Skip {
        $SyslogService.Policy | Should Be $SyslogPolicy
      }

      It "Has the Syslog firewall exception set to $VMHostFirewallException" {
        ($VMHost | Get-VMHostFirewallException -name syslog).Enabled | Should Be $VMHostFirewallException
      }
    }
  }
}

#SSH configuration
Describe "Hosts SSH configuration" {
  Foreach ($VMHost in $VMHosts)
  {
    Context "VMHost $($VMHost.Name)" {

      $SSHService = $VMHost | Get-VMHostService | where{$_.Key -eq "TSM-SSH"}

      It "Has the SSH service set to $SSHRunning" {
        $SSHService.Running | Should Be $SSHRunning
      }

      It "Has the SSH policy set to $NTPPolicy" {
        $SSHService.Policy | Should Be $NTPPolicy
      }

      It "Has the advanced value UserVars.SuppressShellWarning set to $SSHSuppressShellWarning" {
        ($VMHost | Get-AdvancedSetting -Name 'UserVars.SuppressShellWarning').Value | Should Be $SSHSuppressShellWarning
      }
    }
  }
}

#DNS Configuration
Describe "Hosts DNS configuration" {
  Foreach ($VMHost in $VMHosts)
  {
    Context "VMHost $($VMHost.Name)" {

      $VMHostNetwork = Get-VMHostNetwork

      Foreach ($DNS in $DNSAddress) {
        It "Has a DNS Server set to $DNS" {
          $VMHostNetwork.DnsAddress -match $DNS | Should Be $true
        }
      }

      It "Has a DNS domain name set to $DomainName" {
        $VMHostNetwork.DomainName | Should Be $DomainName
      }

      It "Has a DNS search domain set to $SearchDomain" {
        $VMHostNetwork.SearchDomain | Should Be $SearchDomain
      }
    }
  }
}

Disconnect-VIServer -Confirm:$false
