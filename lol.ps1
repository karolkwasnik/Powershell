#skrypt korzysta z api udostepnianego przez Riot Games
#podajemy nick a skrypt sledzi danego uzytkownika w grze League of Legends 
#i wyrzuca powiadomienie jesli ten skonczy gre
#powiadomienie informuje o: nicku gracza, trybie gry, linii, roli oraz 
#o bohaterze jakim zagrano

#obowiazkowy argument jakim jest nick gracza
param(
[Parameter(Mandatory=$true)][string]$nick
)

#jest to funkcja do pokazywania powiadomien, zaczerpnieta z internetu
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
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(60)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}

#kod api udostepniany na 24h przez riot
$api = 'RGAPI-e09dd7dc-7284-4ee7-afe3-314860d1e0b4'

#api Riot Games jest tak skonstruowane ze pierw musze pobrac jedne dane z takiej sciezki
$base = 'https://eun1.api.riotgames.com/tft/summoner/v1/summoners/by-name/'
$base += $nick
$base += '?api_key='
$base += $api

#i wyciagnac z nich accountid
$id_resp = Invoke-RestMethod  $base -Method 'GET' -Headers $headers
[string]$AccID = $id_resp.accountId

#i to accountid uzywam do pobrania nowych danych ze sciezki base_2
$base_2 = 'https://eun1.api.riotgames.com/lol/match/v4/matchlists/by-account/'
$base_2 += $AccID
$base_2 += '?api_key='
$base_2 += $api

#lacze z plikami .json relatywnie do sciezki skryptu
$path = $PSScriptRoot
$path += '\lol.json'
$queue = $PSScriptRoot
$queue += '\queue.json'
$champion = $PSScriptRoot
$champion += '\champion.json'

#jesli nie ma pliku lol.json to go tworzymy
if(-not(Test-Path -Path $path)){
    New-Item $path
}

#w petli pobieramy dane gracza za pomoca api
while(1){
$response = Invoke-RestMethod $base_2 -Method 'GET' -Headers $headers

#pobieramy dane z plikow .json i przypisujemy do tablic
[array]$DBarr = Get-Content -Path $path | ConvertFrom-Json
[array]$Qarr = Get-Content -Path $queue | ConvertFrom-Json
[array]$CHarr = Get-Content -Path $champion | ConvertFrom-Json

#jesli w tablicy z pliku lol.json sa juz jakies dane to warunek jest spelniony
if($DBarr){
    #jesli czas ostatnio rozegranej gry jest wiekszy od czasu zapisanego w bazie danych
    if($response.matches[0].timestamp -gt $DBarr[0].Time){
        #przeszukujemy baze danych aby uzyskac informacje o trybie gry
        [string]$gametype = $response.matches[0].queue
        foreach($tmp in $Qarr){
            if($gametype -eq $tmp.queueID){
                [string]$tryb = $tmp.description
            }
        }

        #przeszukujemy baze danych aby uzyskac informacje o bohaterze
        [string]$champID = $response.matches[0].champion
        foreach($tmp in $CHarr){
            if($champID -eq $tmp.key){
                [string]$champ = $tmp.name
            }
        }

        #tworzymy zmienna wyswietlajaca wiadomosc
        $text =""
        $text += "Tryb: "
        $text += $tryb
        $text += "`nBohater: "
        $text += $champ
        $text += "`nLinia: "
        $text += [string]$response.matches[0].lane
        $text += "`nRola: "
        $text += [string]$response.matches[0].role

        #wlaczamy powiadomienie ktorego tytulem jest nick a trescia jest wyzej stworzona zmienna
        Show-Notification -ToastTitle $nick -ToastText $text
        #uaktualniamy czas w bazie danych
        $DBarr[0].Time = $response.matches[0].timestamp
    }
}
#jesli w bazie nie bylo zadnych danych to zamiast porownywania, zapisujemy je
else{
$Object = New-Object PSObject
$Object | Add-Member -MemberType NoteProperty -Name Time -Value $response.matches[0].timestamp
$DBarr += $Object
}

#uaktualniamy plik z baza danych
$DBarr | ConvertTo-Json | Out-File -FilePath $path

#czekamy
Write-Host "Running..."
Start-Sleep -Seconds 10
}
