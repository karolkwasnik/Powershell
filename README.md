# Powershell
## covid.ps1
  Skrypt korzystający z API w celu wyświetlania aktualnych statystyk dotyczących koronawirusa w poszczególnych krajach
## find_duplicates.ps1
  Skrypt przyjmuje jeden parametr nienazwany, który jest ścieżką do katalogu. Skrypt wyszukuje rekurencyjnie pliki w katalogu i buduje bazę danych hashy, które służą do             wyszukiwania duplikatów. Porównywanie plików polega na sprawdzeniu czy mają taką samą sumę kontrolną. Suma kontrolna liczona jednym z algorytmów funkcji (Get-FileHash)
## monitor-dysk.ps1
  Skrypt monitoruje ilość dostępnego miejsca na dyskach i powiadamia użytkownika jeśli ilość ta spadnie poniżej zadanego %
## monitor-itunes.ps1
  Skrypt monitoruje zadany ebook na itunes i powiadamia użytkownika jeśli jego cena spadnie
## lol.ps1
  Skrypt monitoruje gracza League of Legends poprzez podanie jego nick'u jako argumentu. Gdy gracz ten skończy rozgrywkę, użytkownik dostaje powiadomienie wraz ze statystykami       dotyczącymi rozegranej partii.
  Potrzebne pliki:
  -queue.json
  -lol.json
  -champion.json
