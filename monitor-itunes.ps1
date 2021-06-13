#skrypt monitoruje ceny produktow autorstwa Yuvala Noaha Harariego na itunes i powiadamia uzytkownika jesli cena ktoregos z produktow zmaleje
#skrypt monitoruje rowniez ilosc wolnego miejsca na dyskach

#ładuje zestaw z katalogu aplikacji lub z globalnej pamięci podręcznej zestawów przy użyciu nazwy częściowej.
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#pobieramy dane za pomoca api
$response = Invoke-RestMethod 'https://itunes.apple.com/search?term=harari&lang=en_us' -Method 'GET' -Headers $headers

#wybieramy tylko te produkty ktorych autorem jest Harari
$harari = $response.results | Select-Object -Property collectionid,wrappertype,artistName,collectionName,CollectionPrice| Where-Object artistName  -eq 'Yuval Noah Harari'

#niestety zeby zobaczyc jakiekolwiek zmiany musimy sztucznie podwyzszyc ceny aby kolejne pobranie danych je obnizylo
$harari[2].collectionPrice = 30
$harari[5].collectionPrice = 50

#monitoruje za pomoca nieskonczonej petli
while(1){
    #znow pobieramy dane aby porownac je z danymi pobranymi w momencie odpalenia skryptu
    $response = Invoke-RestMethod 'https://itunes.apple.com/search?term=harari&lang=en_us' -Method 'GET' -Headers $headers

    #nowe dany przypisujemy do nowej zmiennej
    $newharari = $response.results | Select-Object -Property collectionid,wrappertype,artistName,collectionName,CollectionPrice| Where-Object artistName -eq 'Yuval Noah Harari'

    #porownujemy stare i nowe dane
    $compared = Compare-Object -ReferenceObject $harari -DifferenceObject $newharari -Property collectionPrice -IncludeEqual -PassThru

    #wybieramy te rokordy ktore wskazuja na obnizke ceny
    $cheaper = $compared | Where-Object {$_.sideindicator -eq '=>'}

    #jesli tablica nie jest pusta
    if($cheaper){
        #dla kazdego elementu wyswietlamy informacje o zmianach
        foreach($tmp in $cheaper){
            #zmienne zawierajace nazwe produktu, jego rodzaj (np. audiobook, ebook) oraz nowa cene
            $name = $tmp.collectionName
            $type = $tmp.wrapperType
            $newprice = $tmp.collectionPrice

            #wyszukujemy stara cene produktu za pomoca id
            $oldprice_tmp = $harari | Select-Object | Where-Object {$_.collectionid -eq $tmp.collectionid}
            $oldprice = $oldprice_tmp.collectionprice

            #wyswietlamy popup za pomoca windows forms
            $itunesmsg=[System.Windows.Forms.MessageBox]::Show("Price of [$type]$name has changed from $oldprice$ to $newprice$.","New Price",[System.Windows.Forms.MessageBoxButtons]::OK)

            #aktualizujemy cene aby w kolejnym przejsciu petli nie wyswietlala sie ponownie
            ($harari| Where-Object {$_.collectionid -eq $tmp.collectionid}).collectionPrice = $newprice
        }
    }

    #czekamy
    Start-Sleep -Seconds 5
}