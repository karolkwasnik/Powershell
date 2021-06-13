#WMI - Windows Management Instrumentation
#logicaldisk - represents a data source that resolves to an actual local storage device

#funkcja z internetu bo sam bym w zyciu takiej nie napisal ale pokazuje windowsowskie powiadomienia ktore sa ladne
function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($ToastText)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "PowerShell"
    $Toast.Group = "PowerShell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(10)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}

while(1){
    #pobieramy dane na temat dyskow 
    $disk = get-WmiObject win32_logicaldisk

    #dla kazdego obliczamy ilosc wolnego miejsca w procentach
    foreach($tmp in $disk){
        #zaokraglamy do 3 miejsc po przecinku
        $left = [math]::Round(($tmp.FreeSpace/$tmp.Size)*100,3)

        #jesli ilosc spadnie ponizej zadanego % to wyswietlamy komunikat
        if($left -le 90){
            $diskname = $tmp.DeviceID
            Show-Notification -ToastTitle "Disk: $diskname" -ToastText "There is only $left% free disk space left"
        }

        #odczekujemy pomiedzy kazdym powiadomieniem
        Start-Sleep -seconds 10

    }

    #czekamy do ponownego sprawdzania dyskow
    Start-sleep -Seconds 60
}
