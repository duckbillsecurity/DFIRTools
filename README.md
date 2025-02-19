# DFIRTools
Tools to help perform DFIR

## GitDumper

```
.\gitdumper.ps1 https://www.domain.com/.git/ C:\Projects\gitdump\amarconline --git-dir=.git
```

## GitExtractor

1. Download: 64-bit Git for Windows Portable
https://git-scm.com/downloads/win
Extract and copy gitextractor.ps1 to bin directory

2. When run from client, make sure to update path in script to git.exe

```
.\gitextractor.ps1 -GitDir "C:\Projects\gitdump\domain" -DestDir "C:\Projects\gitdump\extract"
```



