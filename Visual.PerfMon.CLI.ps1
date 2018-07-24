$servers = "localhost","remotehost"  ## It takes about 1-2 sec for local and 2-4 sec for server to read out the data
$LimitHighUsedCPU = 85            ## When to show RED for CPU (below this and above $LimitLowUsedCPU will be yellow)
$LimitLowUsedCPU = 20             ## When to show GREEN for CPU (above this and below $LimitMaxUsedCPU will be yellow)
$LimitUsedRAM = 60                ## When to show RED for RAM (while above)
$TimeBetweenRefreshInSeconds = 3  ## Seconds between refresh (it will take a while to gather the data from the servers and depending on that try out what works for you)
$RunTime =  1                     ## How long the script will run in hours
$TempFileDir = "$env:TEMP"        ## Directory for temp data (small txt file)
$ShowCmdTime = $False             ## True/False - True = shows how long commands for each server took
$TimeNow = Get-Date               ## Variable to know how long to run

cls
do{

"" | Out-File $TempFileDir\PerformanceMonitor.txt
"server,ramfree,ramtotal,cpu,cpucores,cmdtimesec,cmdtimemilsec" | Out-File $TempFileDir\PerformanceMonitor.txt


foreach($server in $servers){
$sw = [Diagnostics.Stopwatch]::StartNew()
$wmiram = Get-WmiObject -ComputerName $server -Class Win32_OperatingSystem -ErrorAction stop | select FreePhysicalMemory,TotalVisibleMemorySize 
$wmicpu = Get-WmiObject -ComputerName $server -Class win32_processor -ErrorAction stop | select LoadPercentage | Measure-Object -property LoadPercentage -Average
$wmicpucores = Get-WmiObject -ComputerName $server -Class win32_processor -ErrorAction stop | select NumberOfCores
$sw.Stop()

$outdata = -join($server + ',' + $wmiram.FreePhysicalMemory + ',' + $wmiram.TotalVisibleMemorySize + ',' +$wmicpu.Average + ',' + $wmicpucores.NumberOfCores + ',' + $sw.Elapsed.Seconds + ',' + $sw.Elapsed.Milliseconds)
$outdata | Out-File -Append $TempFileDir\PerformanceMonitor.txt}

$imp_csv = Import-Csv $TempFileDir\PerformanceMonitor.txt

cls
Write-Host -ForegroundColor Yellow "|1%                                                                                            100%|"
foreach($csvrow in $imp_csv){

$cmdtimesec = $csvrow.cmdtimesec
$cmdtimemilsec = $csvrow.cmdtimemilsec
$imp_server = $csvrow.server
$PercentRepRAM = " "
$PercentRepCPU = " "

## RAM and CPU Calculations
$FreeRam = $csvrow.ramfree
$TotalRam = $csvrow.ramtotal
$UsedRam = (100-($FreeRam/$TotalRam)*100)
$UsedRamRound = [math]::round($UsedRam,0)

$cpucores = $csvrow.cpucores
$UsedCPUValue = $csvrow.cpu

$RAMBar = ($PercentRepRAM*$UsedRamRound)
$CPUBar = ($PercentRepCPU*$UsedCPUValue)

## Colors and Texts
if($UsedRamRound -gt $LimitUsedRAM ){
$RAMBgColor = "Red"
$RAMTxtColor = "Red"}
Else{
$RAMBgColor = "Green"
$RAMTxtColor = "Green"}

if([int]$UsedCPUValue -gt $LimitHighUsedCPU){
$CPUBgColor = "DarkRed"
$CPUTxtColor = "Red"}
Elseif([int]$UsedCPUValue -gt $LimitLowUsedCPU -and $UsedCPUValue -lt $LimitHighUsedCPU){
$CPUBgColor = "DarkYellow"
$CPUTxtColor = "Yellow"}
Elseif([int]$UsedCPUValue -lt $LimitLowUsedCPU){
$CPUBgColor = "DarkGreen"
$CPUTxtColor = "Green"}

## Write out in console
Write-Host -ForegroundColor $RAMTxtColor -BackgroundColor $RAMBgColor "$RAMBar" -NoNewline
#Write-Host "$RAMBar2" -NoNewline
Write-Host " $UsedRamRound% RAM used | " -NoNewline
Write-Host -ForegroundColor $RAMTxtColor "$imp_server"

Write-Host -ForegroundColor $CPUTxtColor -BackgroundColor $CPUBgColor "$CPUBar" -NoNewline
#Write-Host "$CPUBar2" -NoNewline
Write-Host " $UsedCPUValue% CPU used ($cpucores cores) | " -NoNewline

if($ShowCmdTime -eq $True){
Write-Host -ForegroundColor $CPUTxtColor "$imp_server" -NoNewline
Write-Host -ForegroundColor Magenta " | Command took: $cmdtimesec sec $cmdtimemilsec milisec "}
elseif($ShowCmdTime -eq $False){
Write-Host -ForegroundColor $CPUTxtColor "$imp_server"}

Write-Host ""
}

start-sleep $TimeBetweenRefreshInSeconds

}
until((Get-Date) -gt $TimeNow.AddHours($RunTime))
