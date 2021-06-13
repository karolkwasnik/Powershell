#pobieramy dane przez API
$response = Invoke-RestMethod 'https://api.covid19api.com/summary' -Method 'GET' -Headers $headers

#petla do liczenia czasu od update'u dla kazdego wiersza
for($i = 0; $i -lt $response.Countries.Length; $i++){

    #bierzemy poszczegolne daty
    $StartDate=$response.Countries[$i].Date

    #bierzemy aktualny czas
    $EndDate= Get-Date

    #liczymy roznice czasu
    $czas = New-TimeSpan -Start $StartDate -End $EndDate

    #warunki dotyczace wyswietlania + nadpisanie zmiennej data
    
    #czas krotszy niz dzien
    if(($czas.Days -eq 0) -and ($czas.Hours -ne 0)){
        $response.Countries[$i].Date = "{0}h {1}m" -f $czas.Hours,$czas.Minutes
    }
  
    #czas krotszy niz godzina
    elseif(($czas.Days -eq 0) -and ($czas.Hours -eq 0)){
        $response.Countries[$i].Date = "{0}m" -f $czas.Minutes
    }
   
    #czas dluzszy niz dzien
    else{
        $response.Countries[$i].Date = "{0}d {1}h {2}m" -f $czas.Days,$czas.Hours,$czas.Minutes
    }
}

#wyswietlenie tabeli
$response.Countries | Select-Object -Property Country,TotalConfirmed,TotalRecovered,TotalDeaths, @{n="Updated"; e={$_.Date}} | Format-Table
