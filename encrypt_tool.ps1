param(
    [string]$InputPath,
    [string]$OutputPath,
    [string]$Passphrase
)

# Prompt for missing parameters if not passed
if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $InputPath = Read-Host "Enter input image path"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Read-Host "Enter output image path"
}

if ([string]::IsNullOrWhiteSpace($Passphrase)) {
    $Passphrase = Read-Host "Enter passphrase"
}

# Validate input file
if (-not (Test-Path -LiteralPath $InputPath -PathType Leaf)) {
    Write-Error "Input file does not exist: $InputPath"
    exit 1
}

try {
    # Read input file bytes
    $data = [System.IO.File]::ReadAllBytes($InputPath)

    # Generate 16-byte random salt and 16-byte random IV
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $salt = New-Object byte[] 16
    $iv = New-Object byte[] 16
    $rng.GetBytes($salt)
    $rng.GetBytes($iv)

    # PBKDF2 Key Derivation (HMAC-SHA1, 1,000,000 iterations, 32 bytes key length)
    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        $Passphrase,
        $salt,
        1000000,
        [System.Security.Cryptography.HashAlgorithmName]::SHA1
    )
    $key = $pbkdf2.GetBytes(32)

    # AES CBC Encryption with PKCS7 Padding
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.KeySize = 256
    $aes.BlockSize = 128
    $aes.Key = $key
    $aes.IV = $iv

    $encryptor = $aes.CreateEncryptor()
    $ciphertext = $encryptor.TransformFinalBlock($data, 0, $data.Length)

    # Combine salt + IV + ciphertext
    $outputBytes = New-Object byte[] ($salt.Length + $iv.Length + $ciphertext.Length)
    [Array]::Copy($salt, 0, $outputBytes, 0, $salt.Length)
    [Array]::Copy($iv, 0, $outputBytes, $salt.Length, $iv.Length)
    [Array]::Copy($ciphertext, 0, $outputBytes, $salt.Length + $iv.Length, $ciphertext.Length)

    # Write output file
    [System.IO.File]::WriteAllBytes($OutputPath, $outputBytes)

    # Cleanup cryptographic objects
    $encryptor.Dispose()
    $aes.Dispose()
    $pbkdf2.Dispose()
    $rng.Dispose()

    Write-Host "Encrypted $InputPath to $OutputPath"
}
catch {
    Write-Error "Failed to encrypt image: $($_.Exception.Message)"
    exit 1
}
