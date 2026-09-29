# Génère les icônes PWA (web/) à partir du logo source.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/make_pwa_icons.ps1 -Source <png>
param(
  [Parameter(Mandatory=$true)][string]$Source
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$web  = Join-Path $root "web"
$icons = Join-Path $web "icons"
if (-not (Test-Path $icons)) { New-Item -ItemType Directory -Path $icons | Out-Null }

function Make-Icon {
  param([string]$Src, [string]$Out, [int]$Size, [switch]$Pad)
  $bytes = [System.IO.File]::ReadAllBytes($Src)
  $ms = New-Object System.IO.MemoryStream(,$bytes)
  $img = [System.Drawing.Image]::FromStream($ms)
  $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.Clear([System.Drawing.Color]::Transparent)
  $inset = if ($Pad) { [int]([math]::Round($Size * 0.12)) } else { 0 }
  $rect = New-Object System.Drawing.Rectangle($inset, $inset, ($Size - 2*$inset), ($Size - 2*$inset))
  $g.DrawImage($img, $rect)
  $g.Dispose(); $img.Dispose()
  $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $ms.Dispose()
  Write-Host "wrote $Out ($Size)"
}

Make-Icon -Source $Source -Out (Join-Path $icons "Icon-192.png")        -Size 192
Make-Icon -Source $Source -Out (Join-Path $icons "Icon-512.png")        -Size 512
Make-Icon -Source $Source -Out (Join-Path $icons "Icon-maskable-192.png") -Size 192 -Pad
Make-Icon -Source $Source -Out (Join-Path $icons "Icon-maskable-512.png") -Size 512 -Pad
Make-Icon -Source $Source -Out (Join-Path $web "favicon.png")           -Size 64
Write-Host "OK"
