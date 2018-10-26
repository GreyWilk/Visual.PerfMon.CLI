##################
## version 0.1   | Small script to visually show ang CPU usage of local or remote computers
## version 0.3   | First big update. Able to show both RAM and avg CPU. Better visuals.
## version 0.5   | Small adjustments to code. No updates or features
## version 0.8   | Added sorting possibility - eighter sort on RAM _or_ CPU
## version 0.8.1 | Added possibility to choose between WMI and CMI. Added comments and version info and made some comments more understandable
## Version 0.8.2 | Added a Try/Catch för the WMI/CIM queries and changed the file name of the temporary file.
## Version 0.8.3 | Added emptying of temporary file and adding null value to variables.
## Version 0.8.4 | Changed file name of temporary file to variable. Changed way to sort between RAM and CPU (now only one variable)
## Version 0.8.7 | Added option for permanent log file (usable for loggig of specific computers (and then lowering the interval of refresh))
## Version 0.9.0 | Added option for different types of output. One normal and one compact version
## Version 0.9.1 | Bug fixes where offline computers could mess up the whole thing. Also added visual Online/Offline status. Added random generated suffix to filenames
##################

## START Editable variables
$servers = "BSRV01","BSRV02","BSRV03","BDT01","BDT02","BDT03","BDT04","BDT05"               ## It takes about 1-2 sec for local and 2-4 sec for server to read out the data
$LimitHighUsedCPU = 85                            ## 1..100. When to show RED for CPU (below this and above $LimitLowUsedCPU will be yellow)
$LimitLowUsedCPU = 20                             ## 1..100. When to show GREEN for CPU (above this and below $LimitMaxUsedCPU will be yellow)
$LimitUsedRAM = 75                                ## 1..100. When to show RED for RAM (while above)
$SortOn = "NAME"                                   ## Current valid values: "NAME", "RAM" and "CPU". This will sort the chosen type to be shown on the top or sorted on server name.
$DisplayType = "COMPACT"                          ## Current valid values: "COMPACT" and "NORMAL".
$TimeBetweenRefreshInSeconds = 3                  ## Seconds between refresh (it will take a while to gather the data from the servers and depending on that try out what works for you)
$RunTime =  7                                     ## How long the script will run in hours
$UseCIM = "NO"                                    ## Yes/No - No uses Get-WMIObject. Yes uses normal CIM.
$LogToPermanentFile = "YES"                        ## Enables logging to "permanent" file which is not removed by script
$PermanentFilePath = "c:\temp"                    ## Path to put permanent logfile
$ErrorPath = "C:\temp"                            ## Path to put error file
$TempFileDir = "C:\temp"                        ## Directory for temp data (small txt file)
$ShowCmdTime = $False                             ## True/False - True = shows how long commands for each server took
## END Editable variables

    ## START Static variables
    $ascii = ([char[]]([char]65..[char]90) + ([char[]]([char]97..[char]122)) + 0..9)
    $Randomness = (1..$(Get-Random -Minimum 6 -Maximum 8) | % {$ascii | get-random}) -join ""
    $TempFileName = "Visual.PerfMon.CLI.Tempdata-$Randomness.txt" ## File name of temporary file (no need to be in the editable variables section :) )
    $PermanentFileName = "permafile-$Randomness.txt"
    $PermanentFileNamePath = -join( $PermanentFilePath + '\' + $PermanentFileName )
    $TempFileFullPath = -join( $TempFileDir + '\' + $TempFileName )
    $TimeNow = Get-Date                               ## Variable to know how long to run
    $ConfWarning1 = ""                                ## Reset warning 1
    $ConfWarning2 = ""                                ## Reset warning 2
    ## END Static variables

        ## START Emptying/populating variables/files
        Remove-Item $TempFileFullPath
        $wmiram = ""
        $wmicpu = ""
        $wmicpucores = ""
        $FreeRam = ""
        $UsedRam = ""
        $TotalRam = ""
        $UsedRamRound = ""
        $cpucores = ""
        $CalculatedRamPercent = ""
                if(!$PermanentFileNamePath){
                "date,time,server,ramfree,ramtotal,rampercent,cpu,cpucores,cmdtimesec,cmdtimemilsec,status" | Out-File $PermanentFileNamePath}
                else{}
        ## END Emptying variables


cls
do{
"" | Out-File $TempFileFullPath
"server,ramfree,ramtotal,rampercent,cpu,cpucores,cmdtimesec,cmdtimemilsec,status" | Out-File $TempFileFullPath

## foreach start
foreach($server in $servers){
$sw = [Diagnostics.Stopwatch]::StartNew()
try{
    $DateStamp = Get-Date -Format FileDate
    $TimeStamp = Get-Date -Format HH:mm:ss

        if($UseCIM -eq "Yes"){
        $CIMSession = New-CimSession -ComputerName $server
        $wmiram = Get-CimInstance -CimSession $CIMSession -ClassName Win32_OperatingSystem  -ErrorAction Stop| select FreePhysicalMemory,TotalVisibleMemorySize
        $wmicpu = Get-CimInstance -CimSession $CIMSession -ClassName Win32_Processor -ErrorAction Stop | Select LoadPercentage | Measure-Object -property LoadPercentage -Average
        $wmicpucores = Get-CimInstance -CimSession $CIMSession -ClassName Win32_Processor -ErrorAction Stop | select NumberOfCores
        Get-CimSession | Remove-CimSession
        }
        Elseif($UseCIM -eq "No"){
        $wmiram = Get-WmiObject -ComputerName $server -Class Win32_OperatingSystem -ErrorAction Stop | select FreePhysicalMemory,TotalVisibleMemorySize 
        $wmicpu = Get-WmiObject -ComputerName $server -Class win32_processor -ErrorAction Stop | select LoadPercentage | Measure-Object -property LoadPercentage -Average
        $wmicpucores = Get-WmiObject -ComputerName $server -Class win32_processor -ErrorAction Stop | select NumberOfCores
        }

        $CalculatedRamPercent = (100-($wmiram.FreePhysicalMemory/$wmiram.TotalVisibleMemorySize)*100)
        $sw.Stop()

        if($LogToPermanentFile -eq "no"){
        $outdata = -join($server + ',' + $wmiram.FreePhysicalMemory + ',' + $wmiram.TotalVisibleMemorySize + ',' + $CalculatedRamPercent + ',' + $wmicpu.Average + ',' + $wmicpucores.NumberOfCores + ',' + $sw.Elapsed.Seconds + ',' + $sw.Elapsed.Milliseconds + ',' + 'Online')
        $outdata | Out-File -Append $TempFileFullPath
        Remove-Item $PermanentFileNamePath -ErrorAction SilentlyContinue
        }
        elseif($LogToPermanentFile -eq "yes"){
        $outdata = -join($server + ',' + $wmiram.FreePhysicalMemory + ',' + $wmiram.TotalVisibleMemorySize + ',' + $CalculatedRamPercent + ',' + $wmicpu.Average + ',' + $wmicpucores.NumberOfCores + ',' + $sw.Elapsed.Seconds + ',' + $sw.Elapsed.Milliseconds + ',' + 'Online')
        $permoutdata = -join($DateStamp + ',' + $TimeStamp + ',' + $server + ',' + $wmiram.FreePhysicalMemory + ',' + $wmiram.TotalVisibleMemorySize + ',' + $CalculatedRamPercent + ',' + $wmicpu.Average + ',' + $wmicpucores.NumberOfCores + ',' + $sw.Elapsed.Seconds + ',' + $sw.Elapsed.Milliseconds + ',' + 'Online')
        $outdata | Out-File -Append $TempFileFullPath
        $permoutdata | Out-File -Append $PermanentFileNamePath
        }

}
catch{
    $ErrorTime = Get-Date -Format 'yyyy-MM-dd-HH:mm:ss'
    $ErrorTime | Out-File -Append $ErrorPath\Visual.PerfMon.CLI.Error.txt
    $Error[0] | Out-File -Append $ErrorPath\Visual.PerfMon.CLI.Error.txt
    "$server,0,0,0,0,0,0,0,Offline" | Out-File -Append $TempFileFullPath
        if($LogToPermanentFile -eq "yes"){
        "$DateStamp,$TimeStamp,$server,0,0,0,0,0,0,0,Offline" | Out-File -Append $PermanentFileNamePath
        }
        else{}
    #break
}

} 
## foreach end

## START IF sort CPU/RAM
    if( $SortOn -eq "RAM" ){
    $imp_csv_sortram = Import-Csv $TempFileFullPath | Sort-Object -Descending { [int]$_.rampercent }
    $imp_csv_sortram | Export-Csv $TempFileFullPath -NoTypeInformation
    }

    elseif( $SortOn -eq "CPU" ){
    $imp_csv_sortcpu = Import-Csv $TempFileFullPath | Sort-Object -Descending { [int]$_.cpu }
    $imp_csv_sortcpu | Export-Csv $TempFileFullPath -NoTypeInformation
    }

    elseif( $SortOn -eq "NAME" ){
    $imp_csv_sortname = Import-Csv $TempFileFullPath | Sort-Object { $_.server }
    $imp_csv_sortname | Export-Csv $TempFileFullPath -NoTypeInformation
    }

    elseif(! $SortOn ){
        $ConfWarning1 = "Configuration error!"
        $ConfWarning2 = "Configuration does not allow sorting for both RAM and CPU. No sorting used."
    }
## END IF sort CPU/RAM

$imp_csv = Import-Csv $TempFileFullPath

cls
if($ConfWarning1 -ne ""){ Write-Host -ForegroundColor Red $ConfWarning1 $ConfWarning2}
else{}
if($DisplayType -eq "NORMAL"){Write-Host -ForegroundColor Yellow "|1%                                                                                            100%|"}
else{}

foreach($csvrow in $imp_csv){
    $cmdtimesec = $csvrow.cmdtimesec
    $cmdtimemilsec = $csvrow.cmdtimemilsec
    $imp_server = $csvrow.server
    $PercentRepRAM = " "
    $PercentRepCPU = " "
    $Status = $csvrow.status

    ## Tidy up RAM and CPU data
    $FreeRam = $csvrow.ramfree
    $TotalRam = $csvrow.ramtotal
    $UsedRam = $csvrow.rampercent
    $UsedRamRound = [math]::round($UsedRam)
    $cpucores = $csvrow.cpucores
    $UsedCPUValue = [math]::round($csvrow.cpu)

    $RAMBar = ($PercentRepRAM*$UsedRamRound)
    $CPUBar = ($PercentRepCPU*$UsedCPUValue)

        if($DisplayType -eq "NORMAL"){

            ## Colors and Texts
            if($UsedRamRound -gt $LimitUsedRAM ){
            $RAMBgColor = "red"
            $RAMTxtColor = "red"}
            Else{
            $RAMBgColor = "green"
            $RAMTxtColor = "green"}
            
            if([int]$UsedCPUValue -gt $LimitHighUsedCPU){
            $CPUBgColor = "DarkRed"
            $CPUTxtColor = "Red"}
            Elseif([int]$UsedCPUValue -gt $LimitLowUsedCPU -and $UsedCPUValue -lt $LimitHighUsedCPU){
            $CPUBgColor = "DarkYellow"
            $CPUTxtColor = "Yellow"}
            Elseif([int]$UsedCPUValue -lt $LimitLowUsedCPU){
            $CPUBgColor = "DarkGreen"
            $CPUTxtColor = "Green"}

            if($Status -eq 'Online'){
            $StatusColor = "DarkGreen"}
            else{$StatusColor = "DarkRed"}
                
            ## Write out in console
                Write-Host -ForegroundColor $RAMTxtColor -BackgroundColor $RAMBgColor "$RAMBar" -NoNewline
                Write-Host " $UsedRamRound% RAM used | " -NoNewline
                Write-Host -ForegroundColor $RAMTxtColor "$imp_server" -NoNewline
                Write-Host -ForegroundColor $StatusColor "($Status)"

                Write-Host -ForegroundColor $CPUTxtColor -BackgroundColor $CPUBgColor "$CPUBar" -NoNewline
                Write-Host " $UsedCPUValue% CPU used ($cpucores cores) | " -NoNewline

                if($ShowCmdTime -eq $True){
                Write-Host -ForegroundColor $CPUTxtColor "$imp_server" -NoNewline
                Write-Host -ForegroundColor Magenta " | Command took: $cmdtimesec sec $cmdtimemilsec milisec "}
                elseif($ShowCmdTime -eq $False){
                Write-Host -ForegroundColor $CPUTxtColor "$imp_server" -NoNewline
                Write-Host -ForegroundColor $StatusColor "($Status)"}

                Write-Host ""
        }
        elseif($DisplayType -eq "COMPACT"){

            ## Colors and Texts
            if($UsedRamRound -gt $LimitUsedRAM ){
            $RAMBgColor = "red"
            $RAMTxtColor = "black"}
            Else{
            $RAMBgColor = "green"
            $RAMTxtColor = "black"}
            
            if([int]$UsedCPUValue -gt $LimitHighUsedCPU){
            $CPUBgColor = "DarkRed"
            $CPUTxtColor = "Red"}
            Elseif([int]$UsedCPUValue -gt $LimitLowUsedCPU -and $UsedCPUValue -lt $LimitHighUsedCPU){
            $CPUBgColor = "DarkYellow"
            $CPUTxtColor = "Yellow"}
            Elseif([int]$UsedCPUValue -lt $LimitLowUsedCPU){
            $CPUBgColor = "DarkGreen"
            $CPUTxtColor = "Green"}

            if($Status -eq 'Online'){
            $StatusColor = "DarkGreen"}
            else{$StatusColor = "DarkRed"}

            ## Write out in console
                if([Int]$UsedRamRound -lt 10){$WriteRAMSpace1 = "   "}
                elseif([Int]$UsedRamRound -ge 10 -and [Int]$UsedRamRound -lt 100){$WriteRAMSpace1 = "  "}
                elseif([Int]$UsedRamRound -gt 99){$WriteRAMSpace1 = " "}
    
                if([Int]$UsedCPUValue -lt 10){$WriteCPUSpace1 = "   "}
                elseif([Int]$UsedCPUValue -ge 10 -and [Int]$UsedCPUValue -lt "100"){$WriteCPUSpace1 = "  "}
                elseif([Int]$UsedCPUValue -gt 99){$WriteCPUSpace1 = " "}

            
                Write-Host -ForegroundColor $RAMTxtColor -BackgroundColor $RAMBgColor "$WriteRAMSpace1"  -NoNewline
                Write-Host -ForegroundColor $RAMTxtColor -BackgroundColor $RAMBgColor "$UsedRamRound% RAM" -NoNewline
                Write-Host -ForegroundColor $RAMTxtColor -BackgroundColor $RAMBgColor "  " -NoNewline
                Write-Host " | " -NoNewline
                Write-Host -ForegroundColor $CPUTxtColor -BackgroundColor $CPUBgColor "$WriteCPUSpace1"  -NoNewline
                Write-Host -ForegroundColor $CPUTxtColor -BackgroundColor $CPUBgColor "$UsedCPUValue% CPU" -NoNewline
                Write-Host -ForegroundColor $CPUTxtColor -BackgroundColor $CPUBgColor "  " -NoNewline
                Write-Host " | " -NoNewline
                Write-Host "$imp_server" -NoNewline
                Write-Host -ForegroundColor $StatusColor "($Status)"
        }
        else{write-host "DisplayType missing in settings"
}
}
start-sleep $TimeBetweenRefreshInSeconds
}

until((Get-Date) -gt $TimeNow.AddHours($RunTime))
