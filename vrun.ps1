if (Test-Path .\Build\main.exe) {
    iex .\Build\main.exe
} else {
    Write-Output(".\Build\main.exe doesn't exist.")
}
