$path = "C:\Users\jacop\.gemini\antigravity\scratch\fake-insta-prop\v2.html"
$content = Get-Content -Path $path -Raw -Encoding UTF8

$issues = @()

# 1. Check for Mojibake characters
$mojibake = @("â", "Ã", "Â", "ã", "ï¿½")
foreach ($pat in $mojibake) {
    if ($content.Contains($pat)) {
        $issues += "Found Mojibake pattern '$pat'"
    }
}

# 2. Check CSS scoping and stroke rules
if ($content -notmatch 'body\[class\*="vfx-mode-"\] \{' -or $content -notmatch 'background-color: #050505 !important;') {
    $issues += "VFX body background is not scoped to dark black on PC desktop"
}

if ($content -notmatch '\.vfx-marker-svg line' -or $content -notmatch 'stroke: #000000 !important;') {
    $issues += "Missing explicit CSS stroke rule for .vfx-marker-svg line"
}

if ($content -notmatch '\.vfx-marker-svg circle' -or $content -notmatch 'fill: #000000 !important;') {
    $issues += "Missing explicit CSS fill rule for .vfx-marker-svg circle"
}

# 3. Check Header Markers
if ($content -match '<section class="p-4 border-b border-zinc-800/40 relative vfx-section-header"[\s\S]*?</section>') {
    $headerHtml = $Matches[0]
    $top_left = ([regex]::Matches($headerHtml, "top-6 left-6")).Count
    $top_right = ([regex]::Matches($headerHtml, "top-6 right-6")).Count
    $avatar_center = ([regex]::Matches($headerHtml, "inset-0 m-auto")).Count
    if ($top_left -ne 1) { $issues += "Header top-6 left-6 count is $top_left (expected 1)" }
    if ($top_right -ne 1) { $issues += "Header top-6 right-6 count is $top_right (expected 1)" }
    if ($avatar_center -lt 1) { $issues += "Header center marker missing" }
} else {
    $issues += "Could not find header section"
}

# 4. Single posts (1,2,3,4,6,7)
$singlePosts = @(1, 2, 3, 4, 6, 7)
foreach ($postId in $singlePosts) {
    if ($content -match "(?s)<article id=`"post-$postId`".*?</article>") {
        $postHtml = $Matches[0]
        $markerCount = ([regex]::Matches($postHtml, 'class="vfx-marker ')).Count
        if ($markerCount -ne 4) {
            $issues += "Post $postId has $markerCount markers (expected exactly 4 corner markers)"
        }
        if ($postHtml -match 'class="vfx-marker[^"]*?\b(inset-0|top-1/2)\b') {
            $issues += "Post $postId contains a center marker! Single posts must NOT have center markers."
        }
    }
}

# 5. Post 5 Carousel
if ($content -match '<article id="post-5"[\s\S]*?</article>') {
    $post5Html = $Matches[0]
    $slidesCount = ([regex]::Matches($post5Html, 'class="carousel-slide relative"')).Count
    if ($slidesCount -ne 5) {
        $issues += "Post 5 carousel has $slidesCount slides (expected 5)"
    }
}

# 6. Check JS Triple Click
if ($content -notmatch "tripleClickTimer = setTimeout") {
    $issues += "Triple click timer missing in JS"
}

Write-Host "--- AUDIT RESULTS ---"
if ($issues.Count -eq 0) {
    Write-Host "SUCCESS: 0 ISSUES FOUND! ALL CHECKS PASSED PERFECTLY!" -ForegroundColor Green
} else {
    Write-Host "FOUND $($issues.Count) ISSUES:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host " - $issue" -ForegroundColor Yellow
    }
}
