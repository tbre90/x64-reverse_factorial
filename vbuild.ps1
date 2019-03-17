# code_directory (run from code_directory)
#     |
#     |__Build
#
# Run as a powershell script
# (save as <something>.ps1)

pushd .\Build

nasm -f win64 ..\main.asm -o main.o
link .\main.o /Entry:main /OUT:main.exe /NODEFAULTLIB /MACHINE:X64 Kernel32.lib

popd
