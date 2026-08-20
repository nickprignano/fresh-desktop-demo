$ErrorActionPreference = 'Continue'
$log = 'C:\FreshDesktopBranding.log'
function Log($m) { "$(Get-Date -Format o)  $m" | Out-File -FilePath $log -Append }

$wallpaperPath = 'C:\Windows\Web\Wallpaper\FreshDesktop\fresh-desktop.jpg'

try {
  Log 'Starting Fresh Desktop branding'
  Add-Type -AssemblyName System.Drawing

  $width = 1920; $height = 1080
  $bmp = New-Object System.Drawing.Bitmap $width, $height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $green = [System.Drawing.Color]::FromArgb(0,146,70)
  $white = [System.Drawing.Color]::FromArgb(244,245,240)
  $red   = [System.Drawing.Color]::FromArgb(205,33,42)
  $stripe = [Math]::Ceiling($width / 3)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush $green), 0, 0, $stripe, $height)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush $white), $stripe, 0, $stripe, $height)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush $red), (2*$stripe), 0, ($width-(2*$stripe)), $height)

  $overlayBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190, 11, 18, 32))
  $panelH = 260
  $panelY = [int](($height - $panelH) / 2)
  $g.FillRectangle($overlayBrush, 0, $panelY, $width, $panelH)

  $fontTitle = New-Object System.Drawing.Font('Segoe UI', 66, [System.Drawing.FontStyle]::Bold)
  $fontSub = New-Object System.Drawing.Font('Segoe UI', 24, [System.Drawing.FontStyle]::Regular)
  $brushWhite = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment = [System.Drawing.StringAlignment]::Center

  # --- Pizza-slice icon, drawn as vector shapes rather than an emoji glyph -- GDI+ has no reliable
  # cross-build way to render color emoji fonts, so a literal slice-of-pizza glyph risks showing as a
  # blank box on some Windows images. A simple wedge (triangle + curved crust + pepperoni dots) reads as
  # "pizza" at a glance without that risk. Kept strictly inside the existing tricolor + dark-background
  # palette -- white for the crust/cheese base, red for pepperoni, a couple of green flecks for texture --
  # no new colors introduced. Paired to the left of the title text so the wallpaper mirrors the page's
  # "[pizza emoji] Fresh Desktop" icon-then-text brand treatment instead of being text-only.
  $titleText = 'Fresh Desktop'
  $titleSize = $g.MeasureString($titleText, $fontTitle)
  $iconSize = 90
  $iconGap = 20
  $groupWidth = $iconSize + $iconGap + $titleSize.Width
  $groupLeft = [int](($width - $groupWidth) / 2)
  $iconX = $groupLeft
  $iconY = $panelY + 40
  $textX = $iconX + $iconSize + $iconGap
  $textY = $panelY + 35

  $tipX = $iconX + ($iconSize / 2)
  $topY = $iconY
  $leftX = $iconX
  $rightX = $iconX + $iconSize

  $sliceBrush = New-Object System.Drawing.SolidBrush $white
  $crustColor = [System.Drawing.Color]::FromArgb(230, 11, 18, 32)
  $crustBrush = New-Object System.Drawing.SolidBrush $crustColor
  $pepperoniBrush = New-Object System.Drawing.SolidBrush $red
  $basilBrush = New-Object System.Drawing.SolidBrush $green
  $outlineColor = [System.Drawing.Color]::FromArgb(160, 11, 18, 32)
  $outlinePen = New-Object System.Drawing.Pen $outlineColor, 3

  [System.Drawing.PointF[]]$slicePoints = @(
    (New-Object System.Drawing.PointF($tipX, ($topY + $iconSize))),
    (New-Object System.Drawing.PointF($leftX, $topY)),
    (New-Object System.Drawing.PointF($rightX, $topY))
  )
  $g.FillPolygon($sliceBrush, $slicePoints)
  $g.DrawPolygon($outlinePen, $slicePoints)

  $crustRect = New-Object System.Drawing.RectangleF($leftX, ($topY - 8), $iconSize, 20)
  $g.FillPie($crustBrush, $crustRect.X, $crustRect.Y, $crustRect.Width, $crustRect.Height, 180, 180)

  $pepR = 7
  $pepPositions = @(
    @{ x = $tipX;        y = ($topY + $iconSize * 0.42) },
    @{ x = ($tipX - 18); y = ($topY + $iconSize * 0.60) },
    @{ x = ($tipX + 18); y = ($topY + $iconSize * 0.60) },
    @{ x = $tipX;        y = ($topY + $iconSize * 0.78) }
  )
  foreach ($p in $pepPositions) {
    $g.FillEllipse($pepperoniBrush, ($p.x - $pepR), ($p.y - $pepR), ($pepR * 2), ($pepR * 2))
  }

  $basilR = 3
  $g.FillEllipse($basilBrush, ($tipX - 9 - $basilR), ($topY + $iconSize * 0.30 - $basilR), ($basilR * 2), ($basilR * 2))
  $g.FillEllipse($basilBrush, ($tipX + 13 - $basilR), ($topY + $iconSize * 0.48 - $basilR), ($basilR * 2), ($basilR * 2))

  $g.DrawString($titleText, $fontTitle, $brushWhite, (New-Object System.Drawing.PointF($textX, $textY)))
  $g.DrawString('Made fresh to order', $fontSub, $brushWhite, (New-Object System.Drawing.RectangleF(0, ($panelY+145), $width, 60)), $sf)

  $dir = Split-Path $wallpaperPath
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $bmp.Save($wallpaperPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
  $g.Dispose(); $bmp.Dispose()
  Log "Wallpaper generated at $wallpaperPath"

  $polKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
  New-Item -Path $polKey -Force | Out-Null
  Set-ItemProperty -Path $polKey -Name DesktopImagePath -Value $wallpaperPath -Type String
  Set-ItemProperty -Path $polKey -Name DesktopImageUrl -Value $wallpaperPath -Type String
  Set-ItemProperty -Path $polKey -Name DesktopImageStatus -Value 1 -Type DWord
  Log 'Applied machine-wide desktop image policy'
} catch {
  Log "Wallpaper step failed: $_"
}

try {
  reg load 'HKU\FreshDefault' 'C:\Users\Default\NTUSER.DAT' 2>&1 | Out-Null

  $themeKey = 'Registry::HKU\FreshDefault\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
  New-Item -Path $themeKey -Force | Out-Null
  Set-ItemProperty -Path $themeKey -Name AppsUseLightTheme -Value 0 -Type DWord
  Set-ItemProperty -Path $themeKey -Name SystemUsesLightTheme -Value 0 -Type DWord
  Set-ItemProperty -Path $themeKey -Name ColorPrevalence -Value 1 -Type DWord

  $dwmKey = 'Registry::HKU\FreshDefault\Software\Microsoft\Windows\DWM'
  New-Item -Path $dwmKey -Force | Out-Null
  Set-ItemProperty -Path $dwmKey -Name AccentColor -Value 0xFF469200 -Type DWord
  Set-ItemProperty -Path $dwmKey -Name ColorizationColor -Value 0xC4469200 -Type DWord
  Set-ItemProperty -Path $dwmKey -Name ColorizationAfterglow -Value 0xC4469200 -Type DWord

  $deskKey = 'Registry::HKU\FreshDefault\Control Panel\Desktop'
  New-Item -Path $deskKey -Force | Out-Null
  Set-ItemProperty -Path $deskKey -Name Wallpaper -Value $wallpaperPath -Type String
  Set-ItemProperty -Path $deskKey -Name WallpaperStyle -Value '10' -Type String
  Set-ItemProperty -Path $deskKey -Name TileWallpaper -Value '0' -Type String
  Log 'Seeded default user theme/accent/wallpaper'
} catch {
  Log "Default profile seeding failed: $_"
} finally {
  [gc]::Collect()
  Start-Sleep -Seconds 2
  reg unload 'HKU\FreshDefault' 2>&1 | Out-Null
}

Log 'Fresh Desktop branding complete'
