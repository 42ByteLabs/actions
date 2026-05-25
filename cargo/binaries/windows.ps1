# Build Windows executables (.exe) for x86_64 architecture
# PowerShell script for Windows builds

$ErrorActionPreference = "Stop"

if (-not $env:CRATE) {
    Write-Error "Error: CRATE environment variable not set"
    exit 1
}

if (-not $env:VERSION) {
    Write-Error "Error: VERSION environment variable not set"
    exit 1
}

$TARGET = "x86_64-pc-windows-msvc"
$ARCH_NAME = "x86_64"
$BINARY_NAME = "$env:CRATE-$env:VERSION-$ARCH_NAME.exe"

Write-Host "🪟 Building Windows binary :: $BINARY_NAME" -ForegroundColor Cyan

# Build binary
if ($env:FEATURES) {
    cargo build --release -p $env:CRATE --target $TARGET --features $env:FEATURES
} else {
    cargo build --release -p $env:CRATE --target $TARGET
}

# Move binary to output location
Move-Item "target/$TARGET/release/$env:CRATE.exe" $BINARY_NAME -Force

Write-Host "✅ Binary built: $BINARY_NAME" -ForegroundColor Green
"binary-name=$BINARY_NAME" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8

# Create installer if requested (using WiX or NSIS)
if ($env:CREATE_INSTALLER -eq "true") {
    Write-Host "📦 Creating Windows installer..." -ForegroundColor Cyan
    
    # Check if WiX is available
    if (Get-Command "candle.exe" -ErrorAction SilentlyContinue) {
        Write-Host "Using WiX Toolset to create MSI installer..." -ForegroundColor Yellow
        
        $MSI_NAME = "$env:CRATE-$env:VERSION-$ARCH_NAME.msi"
        
        # Create basic WiX XML
        $WXS_CONTENT = @"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="$env:CRATE" Language="1033" Version="$env:VERSION" 
           Manufacturer="42ByteLabs" UpgradeCode="$(New-Guid)">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" />
    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />
    <MediaTemplate EmbedCab="yes" />
    
    <Feature Id="ProductFeature" Title="$env:CRATE" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>
    
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="$env:CRATE" />
      </Directory>
    </Directory>
    
    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <Component Id="MainExecutable" Guid="$(New-Guid)">
        <File Id="MainExe" Source="$BINARY_NAME" KeyPath="yes" />
      </Component>
    </ComponentGroup>
  </Product>
</Wix>
"@
        
        $WXS_CONTENT | Out-File -FilePath "installer.wxs" -Encoding utf8
        
        # Compile and link
        candle.exe installer.wxs
        light.exe -out $MSI_NAME installer.wixobj
        
        if (Test-Path $MSI_NAME) {
            Write-Host "✅ MSI installer created: $MSI_NAME" -ForegroundColor Green
            "msi-name=$MSI_NAME" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
        }
    } else {
        Write-Host "⚠️  WiX Toolset not found. Skipping installer creation." -ForegroundColor Yellow
        Write-Host "Install WiX from: https://wixtoolset.org/" -ForegroundColor Yellow
    }
}

Write-Host "🎉 Windows build complete" -ForegroundColor Green
