$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$outDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'App/Assets.xcassets/AppIcon.appiconset'
$outPath = Join-Path $outDir 'icon-1024.png'
$bitmap = [System.Drawing.Bitmap]::new(1024, 1024)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.Point]::new(0, 0),
    [System.Drawing.Point]::new(1024, 1024),
    [System.Drawing.Color]::FromArgb(13, 24, 48),
    [System.Drawing.Color]::FromArgb(29, 48, 80)
)
$track = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(51, 79, 107), 58)
$progress = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 117, 88), 58)
$figure = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(248, 251, 255), 39)
$ground = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(102, 205, 199), 24)
$head = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(248, 251, 255))

foreach ($pen in @($track, $progress, $figure, $ground)) {
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
}

try {
    $graphics.FillRectangle($background, 0, 0, 1024, 1024)
    $graphics.DrawEllipse($track, 140, 140, 744, 744)
    $graphics.DrawArc($progress, 140, 140, 744, 744, -90, 285)

    # A push-up figure drawn with broad geometric strokes for legibility at icon size.
    $graphics.FillEllipse($head, 292, 416, 94, 94)
    $graphics.DrawLine($figure, 396, 486, 625, 457)
    $graphics.DrawLine($figure, 625, 457, 724, 551)
    $graphics.DrawLine($figure, 724, 551, 767, 562)
    $graphics.DrawLine($figure, 434, 489, 468, 591)
    $graphics.DrawLine($figure, 468, 591, 521, 591)
    $graphics.DrawLine($ground, 310, 637, 764, 637)

    $bitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $outPath
}
finally {
    $head.Dispose()
    $ground.Dispose()
    $figure.Dispose()
    $progress.Dispose()
    $track.Dispose()
    $background.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
