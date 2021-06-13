#https://stackoverflow.com/questions/23720045/powershell-how-to-add-something-on-parsed-json

#wymagany parametr ktory jest sciezka do folderu ktory bedzie przeszukiwany
param(
[Parameter(Mandatory=$true)][string]$path
)

#bierzemy aktualna lokalizacje uzytkownika i tworzymy na jej podstawie sciezke do pliku z baza danych
$database = Get-Location
$database = $database.Path
$database = $database += '\hash.json'

#sprawdzamy czy plik z baza danych juz istnieje, jesli nie to go tworzymy
if(-not(Test-Path -Path $database)){
    New-Item $database
}

#pobieramy dane z bazy danych w pliku hash.json
[array]$DBarr = Get-Content -Path $database | ConvertFrom-Json

#sprawdzamy czy w bazie danych jest juz rekord o takiej sciezce i przypisujemy objectid miejsce tego rekordu w tablicy
#jesli nie ma rekordu dla tej sciezki to objectid pozostaje z wartoscia -1
$ObjectID = -1
if($DBarr){
    for($i = 0; $i -lt $DBarr.Length; $i++){
        if($DBarr[$i].Path -eq $path){
        $ObjectID = $i
        }
    }
}

#jesli danej sciezki nie ma w bazie danych to tworzymy nowy obiekt
if($ObjectID -eq -1){
    #pobieramy rekurencyjnie wszystkie pliki i obliczamy dla nich hashe za pomoca podprocesow
    $j = Get-ChildItem -Path $path -Recurse -File | Start-Job -ScriptBlock {Get-FileHash}
    $x = Wait-job $j
    $files = Receive-job $j

    #tworzymy nowy obiekt i przypisujemy do niego odpowiednie wartosci
    $Object = New-Object PSObject
    $Object | Add-Member -MemberType NoteProperty -Name Path -Value $path
    $Object | Add-Member -MemberType NoteProperty -Name LastWrite -Value (Get-Date).DateTime
    $Object | Add-Member -MemberType NoteProperty -Name FilePath -Value $files.Path
    $Object | Add-Member -MemberType NoteProperty -Name Hash -Value $files.Hash

    #dodajemy obiekt do bazy danych
    $DBarr += $Object

    #obliczamy duplikaty i zapisujemy je do zmiennej
    $duplicates = $Object.hash | Group-Object | Where-Object {$_.Count -gt 1}
}

#jesli sciezka juz jest w bazie danych to edytujemy istniejacy juz obiekt
else{
    #pobieramy pliki dla porownania
    $files = Get-ChildItem -Path $path -Recurse -File 

    #petle wraz z warunkiem w celu dodania nowych plikow
    for($i = 0; $i -lt $files.Length; $i++){
        #warunek: prawda - dodajemy plik; falsz - nie dodajemy pliku
        $condition = $true
        for($j = 0; $j -lt $DBarr[$ObjectID].FilePath.Length; $j++){
            if($files[$i].FullName -eq $DBarr[$ObjectID].FilePath[$j]){
                #jesli napotkamy plik o takiej nazwie to zmieniamy warunek na falsz
                $condition = $false
            }
        }
        #jesli nie napotkalismy w obiekcie pliku o takiej samej nazwie to go dodajemy przy pomocy podprocesow
        if($condition -eq $true){
            $DBarr[$ObjectID].FilePath += $files[$i].FullName
            $job = $files[$i] | Start-Job -ScriptBlock {Get-fileHash}
            $w = Wait-Job $job
            $tmp_hash = Receive-Job $job
            $DBarr[$ObjectID].Hash += $tmp_hash.Hash
        }
    }
    
    #petla wraz z warunkiem do obliczania hashy plikow ktorych data edycji jest nowsza niz data ostatniego odpalenia skryptu
    for($i = 0; $i -lt $files.Length; $i++){
        $time = NEW-TIMESPAN –Start $files[$i].LastWriteTime –End $DBarr[$ObjectID].LastWrite
        if($time -lt 0){
            $job = $files[$i] | Start-Job -ScriptBlock {Get-fileHash}
            $w = Wait-Job $job
            $tmp_hash = Receive-Job $job
            $DBarr[$ObjectID].Hash[$i] = $tmp_hash.Hash
        }
    }

    #uaktualniamy date odpalenia skryptu
    $DBarr[$ObjectID].LastWrite = (Get-Date).DateTime

    #obliczamy duplikaty i zapisujemy je do zmiennej
    $duplicates = $DBarr[$ObjectID].hash | Group-Object | Where-Object {$_.Count -gt 1}
}

#konwertujemy baze danych do json'a i zapisujemy do pliku
$DBarr | ConvertTo-Json | Out-File -FilePath $database

#wypisujemy sciezki duplikatow wraz z ich hashami
if($duplicates){
    "`nDuplikaty: "
    for($i = 0; $i -lt $duplicates.Length; $i++){
        for($j = 0; $j -lt $DBarr[$ObjectID].Hash.Length; $j++){
            if($duplicates[$i].Group[0] -eq $DBarr[$ObjectID].Hash[$j]){
              "{0} `t`t {1}" -f $duplicates[$i].Group[0],$DBarr[$ObjectID].FilePath[$j]    
            }
        }
    }
}

Write-Host "Done"