function Set-VMhostTime {
    [cmdletbinding()]
     Param([Parameter(Mandatory=$true)][string]$Name)
    $filter = @{'Name'=$Name}
    $vmhosts = get-view -ViewType HostSystem -Property Name,configmanager.datetimesystem -filter $filter
    $vmhosts | ForEach-Object {    
        #get host datetime system
        write-verbose "Checking $($_.Name)"
        $dts = get-view $_.configManager.DateTimeSystem
        foreach ($d in $dts) {
            #get host time
            $before = $d.QueryDateTime()
            $date = (get-date).ToUniversalTime()
            $s = [math]::abs(($before - $date).TotalSeconds)
        
            $d.UpdateDateTime($date)
        
            $after = $d.QueryDateTime()

            #set ntp servers:
            $ntp = New-Object VMware.Vim.HostNtpConfig
            #$ntp.Server = ("tick.usace.army.mil", "tock.usace.army.mil")
            $ntp.Server = ("10.62.53.130","10.62.53.131")
            $dt = New-Object VMware.Vim.HostDateTimeConfig
            $dt.NtpConfig = $ntp
            $d.UpdateDateTimeConfig($dt)

            #set policy
            $ntpd = Get-VMHostService -VMHost $Name | Where-Object key -eq ntpd 
            $ntpd | Set-VMHostService -Policy On | out-null
            $ntpd | Start-VMHostService -Confirm:$false | out-null

            $row = "" | Select-Object HostName,SecondsOffBy,TimeNow
            $row.HostName = $_.Name
            $row.SecondsOffBy = $s
            $row.Timenow = $after.tolocaltime()
            $row
        }
    }
}
