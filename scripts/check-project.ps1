$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    'project.yml',
    'App/Info.plist',
    'App/FocusRepDemoApp.swift',
    'App/FocusSession.swift',
    'App/ContentView.swift',
    'App/ChallengeView.swift',
    'Shared/FocusActivityAttributes.swift',
    'Widget/Info.plist',
    'Widget/FocusRepWidget.swift',
    '.github/workflows/ios-compile.yml'
)
foreach ($relativeFile in $requiredFiles) {
    $fullPath = Join-Path $projectRoot $relativeFile
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Missing project file: $relativeFile"
    }
}

[xml]$appPlist = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'App/Info.plist')
[xml]$widgetPlist = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'Widget/Info.plist')
if ($appPlist.plist.dict.key -notcontains 'NSSupportsLiveActivities') {
    throw 'App does not declare Live Activities support.'
}
if ($appPlist.plist.dict.key -notcontains 'CFBundleURLTypes') {
    throw 'App does not declare the focusrep deep link.'
}
if ($widgetPlist.plist.dict.key -notcontains 'NSExtension') {
    throw 'Widget extension configuration is missing.'
}

$projectSpec = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'project.yml')
if ($projectSpec -notmatch 'FocusRepWidget:' -or $projectSpec -notmatch 'embed: true') {
    throw 'The app does not embed the Live Activity widget.'
}

$widgetSource = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'Widget/FocusRepWidget.swift')
foreach ($token in @('DynamicIslandExpandedRegion', 'compactLeading:', 'compactTrailing:', 'minimal:', 'timerInterval:', 'focusrep://challenge')) {
    if (-not $widgetSource.Contains($token)) {
        throw "Missing Live Activity presentation element: $token"
    }
}

Write-Output 'Project structure, plist files, widget embedding, and presentation declarations: OK'
Write-Output 'Swift compilation and iPhone behavior: not tested on Windows'
