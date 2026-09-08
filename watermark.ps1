param(
    [string]$InputPath,
    [string]$OutputPath,
    [string]$ForUseWith
)

function Add-Watermark {
    param(
        [byte[]]$ImageBytes,
        [string]$UseWith
    )

    Add-Type -AssemblyName System.Drawing

    # Load image from bytes
    $inputStream = New-Object System.IO.MemoryStream(,$ImageBytes)
    $image = [System.Drawing.Image]::FromStream($inputStream)

    # Create RGBA-compatible bitmap
    $bitmap = New-Object System.Drawing.Bitmap(
        $image.Width,
        $image.Height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )

    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.DrawImage($image, 0, 0, $image.Width, $image.Height)

    $width  = $bitmap.Width
    $height = $bitmap.Height

    # Font size scaling
    $fontSize = [Math]::Max(12, [int]($width * 0.025))

    # Try DejaVu Sans, then fall back to Arial
    $fontPath = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

    if (Test-Path $fontPath) {
        $fontFamily = New-Object System.Drawing.FontFamily($fontPath)
        $font = New-Object System.Drawing.Font(
            $fontFamily,
            $fontSize,
            [System.Drawing.FontStyle]::Regular,
            [System.Drawing.GraphicsUnit]::Pixel
        )
    }
    else {
        $font = New-Object System.Drawing.Font(
            "Arial",
            $fontSize,
            [System.Drawing.FontStyle]::Regular,
            [System.Drawing.GraphicsUnit]::Pixel
        )
    }

    $dateStr = (Get-Date).ToString("yyyy-MM-dd")
    $watermarkText = "for usage with $UseWith only at $dateStr"

    # Measure text
    $measureBitmap = New-Object System.Drawing.Bitmap 1, 1
    $measureGraphics = [System.Drawing.Graphics]::FromImage($measureBitmap)
    $textSize = $measureGraphics.MeasureString($watermarkText, $font)

    $tw = [int][Math]::Ceiling($textSize.Width)
    $th = [int][Math]::Ceiling($textSize.Height)

    $measureGraphics.Dispose()
    $measureBitmap.Dispose()

    # Padding
    $paddingX = 40
    $paddingY = 40

    $stampW = $tw + $paddingX
    $stampH = $th + $paddingY

    # Create transparent stamp
    $stamp = New-Object System.Drawing.Bitmap(
        $stampW,
        $stampH,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )

    $stampGraphics = [System.Drawing.Graphics]::FromImage($stamp)
    $stampGraphics.Clear([System.Drawing.Color]::Transparent)

    # Gray with alpha 178
    $brush = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(178, 128, 128, 128)
    )

    $stampGraphics.DrawString(
        $watermarkText,
        $font,
        $brush,
        [int]($paddingX / 2),
        [int]($paddingY / 2)
    )

    # Tile watermark across the image
    for ($y = 0; $y -lt $height; $y += $stampH) {
        for ($x = 0; $x -lt $width; $x += $stampW) {
            $graphics.DrawImage($stamp, $x, $y, $stampW, $stampH)
        }
    }

    # Save as JPEG
    $outputStream = New-Object System.IO.MemoryStream

    $bitmap.Save(
        $outputStream,
        [System.Drawing.Imaging.ImageFormat]::Jpeg
    )

    # Return JPEG bytes
    $result = $outputStream.ToArray()

    # Cleanup
    $brush.Dispose()
    $stampGraphics.Dispose()
    $stamp.Dispose()
    $font.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
    $image.Dispose()
    $inputStream.Dispose()
    $outputStream.Dispose()

    return $result
}


# Prompt for missing parameters
if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $InputPath = Read-Host "Enter input image path"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Read-Host "Enter output image path"
}

if ([string]::IsNullOrWhiteSpace($ForUseWith)) {
    $ForUseWith = Read-Host "Enter 'for use with' value"
}

# Validate input file
if (-not (Test-Path -LiteralPath $InputPath -PathType Leaf)) {
    Write-Error "Input file does not exist: $InputPath"
    exit 1
}

try {
    # Read input image
    $imageBytes = [System.IO.File]::ReadAllBytes($InputPath)

    # Add watermark
    $result = Add-Watermark `
        -ImageBytes $imageBytes `
        -UseWith $ForUseWith

    # Write output image
    [System.IO.File]::WriteAllBytes($OutputPath, $result)

    Write-Host "Watermarked image written to: $OutputPath"
}
catch {
    Write-Error "Failed to process image: $($_.Exception.Message)"
    exit 1
}