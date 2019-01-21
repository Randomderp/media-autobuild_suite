#!/usr/bin/env powershell

<#
-----------------------------------------------------------------------------
 LICENSE --------------------------------------------------------------------
-----------------------------------------------------------------------------
  This Windows Batchscript is for setup a compiler environment for building
  ffmpeg and other media tools under Windows.

    Copyright (C) 2013  jb_alvarado

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
-----------------------------------------------------------------------------
#>

<#
.SYNOPSIS

Builds packages for use with a Windows system.

.Description

Builds ffmpeg, aom, bmx, curl, cyanrip, dav1d, dssim, faac, fdk-aac, fmbc, flac, haisrt tools, jq, kvazaar, lame, libaacs, libbdplus, mediainfo, mp4box, mplayer, mpv, opus, redshift, rtmpdump, rav1e, ripgrep, sox, speex, tesseract, vorbis, vpx, vvc, webp, x264, x265, and xvid.

.INPUTS

None. You cannot pipe anything.

.OUTPUTS

Probably some kind of string, idk at this point.

.EXAMPLE

C:\media-autobuild_suite> .\media-autobuild_suite.ps1

.LINK
https://github.com/jb-alvarado/media-autobuild_suite

#>

if ($PSVersionTable.PSVersion.Major -lt 4) {
    Write-Output "$("-".padright([Console]::bufferwidth-1,"-"))`nYour Powershell version is too low!`nPlease update your version either through an OS upgrade`nor download the latest version for your system from`nhttps://github.com/PowerShell/PowerShell`n$("-".padright([Console]::bufferwidth-1,"-"))`n"
    Pause
    exit
}
#requires -Version 4
if ($PSScriptRoot -match " ") {
    Write-Output "$("-".padright([Console]::bufferwidth-1,"-"))`nYou have probably run the script in a path with spaces.`n`nThis is not supported.`n`nPlease move the script to use a path without spaces. Example:`n`nIncorrect: C:\build suite\`n`nCorrect:   C:\build_suite\`n$("-".padright([Console]::bufferwidth-1,"-"))"
    Pause
    exit
} elseif ($PSScriptRoot.Length -gt 60) {
    Write-Output "$("-".padright([Console]::bufferwidth-1,"-"))`nThe total filepath to the suite seems too large (larger than 60 characters):`n`n$PSScriptRoot`n`nSome packages might fail building because of it.`n`nPlease move the suite directory closer to the root of your drive and maybe`n`nrename the suite directory to a smaller name. Examples:`n`nAvoid:  C:\Users\Administrator\Desktop\testing\media-autobuild_suite-master`n`nPrefer: C:\media-autobuild_suite or `n`nPrefer: C:\ab-suite`n$("-".padright([Console]::bufferwidth-1,"-"))"
    pause
    exit
} else {
    Set-Location $PSScriptRoot
}

$build = "$PSScriptRoot\build"
$json = "$build\media-autobuild_suite.json"
$Host.UI.RawUI.WindowTitle = "media-autobuild_suite"
$PSDefaultParameterValues["Out-File:Encoding"] = "UTF8"
$PSDefaultParameterValues["Set-Content:Encoding"] = "UTF8"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
New-Item -ItemType Directory -Force -Path $PSScriptRoot\build -ErrorAction Ignore | Out-Null

$msyspackages = "asciidoc", "autoconf", "autoconf-archive", "autogen", "automake-wrapper", "bison", "diffstat", "dos2unix", "doxygen", "flex", "git", "gperf", "gyp-git", "help2man", "intltool", "itstool", "libtool", "make", "man-db", "mercurial", "mintty", "p7zip", "patch", "python", "ruby", "subversion", "texinfo", "unzip", "wget", "winpty", "xmlto", "zip"
$mingwpackages = "cmake", "dlfcn", "libpng", "gcc", "nasm", "pcre", "tools-git", "yasm", "ninja", "pkg-config", "meson"
$ffmpeg_options_builtin = "--disable-autodetect", "amf", "bzlib", "cuda", "cuvid", "d3d11va", "dxva2", "iconv", "lzma", "nvenc", "schannel", "zlib", "sdl2", "--disable-debug", "ffnvcodec", "nvdec"
$ffmpeg_options_basic = "gmp", "libmp3lame", "libopus", "libvorbis", "libvpx", "libx264", "libx265", "libdav1d"
$ffmpeg_options_zeranoe = "fontconfig", "gnutls", "libass", "libbluray", "libfreetype", "libmfx", "libmysofa", "libopencore-amrnb", "libopencore-amrwb", "libopenjpeg", "libsnappy", "libsoxr", "libspeex", "libtheora", "libtwolame", "libvidstab", "libvo-amrwbenc", "libwavpack", "libwebp", "libxml2", "libzimg", "libshine", "gpl", "openssl", "libtls", "avisynth", "mbedtls", "libxvid", "libaom", "version3"
$ffmpeg_options_full = "chromaprint", "cuda-sdk", "decklink", "frei0r", "libbs2b", "libcaca", "libcdio", "libfdk-aac", "libflite", "libfribidi", "libgme", "libgsm", "libilbc", "libkvazaar", "libmodplug", "libnpp", "libopenh264", "libopenmpt", "librtmp", "librubberband", "libssh", "libtesseract", "libxavs", "libzmq", "libzvbi", "opencl", "opengl", "libvmaf", "libcodec2", "libsrt", "ladspa", "#vapoursynth", "#liblensfun", "libndi_newtek"
$mpv_options_builtin = "#cplayer", "#manpage-build", "#lua", "#javascript", "#libass", "#libbluray", "#uchardet", "#rubberband", "#lcms2", "#libarchive", "#libavdevice", "#shaderc", "#crossc", "#d3d11", "#jpeg"
$mpv_options_basic = "--disable-debug-build", "--lua=luajit"
$mpv_options_full = "dvdread", "dvdnav", "cdda", "egl-angle", "vapoursynth", "html-build", "pdf-build", "libmpv-shared"
$jsonObjects = [PSCustomObject]@{
    msys2Arch    = [System.IntPtr]::Size / 4
    arch         = 0
    license2     = 0
    standalone   = 0
    vpx2         = 0
    aom          = 0
    rav1e        = 0
    dav1d        = 0
    x2643        = 0
    x2652        = 0
    other265     = 0
    vvc          = 0
    flac         = 0
    fdkaac       = 0
    faac         = 0
    mediainfo    = 0
    soxB         = 0
    ffmpegB2     = 0
    ffmpegUpdate = 0
    mpv          = 0
    ffmpegChoice = 0
    mp4box       = 0
    rtmpdump     = 0
    mplayer2     = 0
    bmx          = 0
    curl         = 0
    ffmbc        = 0
    cyanrip2     = 0
    redshift     = 0
    ripgrep      = 0
    jq           = 0
    dssim        = 0
    cores        = 0
    deleteSource = 0
    strip        = 0
    pack         = 0
    logging      = 0
    updateSuite  = 0
    copybin      = 0
    installdir   = $null
}

if (Test-Path -Path $json) {
    $jsonProperties = Get-Content $json | ConvertFrom-Json
    foreach ($a in $jsonProperties.psobject.Properties.Name) {
        if ($jsonProperties.$a -ne 0) {
            $jsonObjects.$a = $jsonProperties.$a
        }
    }
}
$jsonObjects | ConvertTo-Json | Out-File $json

function Write-Question ($Question) {
    Write-Output "$("-"*80)`n$("-"*80)`n"
    switch ($Question) {
        arch {Write-Output "Select the build target system:"}
        license2 {Write-Output "Build FFmpeg with which license?"}
        standalone {Write-Output "Build standalone binaries for libraries included in FFmpeg?`neg. Compile opusenc.exe if --enable-libopus"}
        vpx2 {Write-Output "Build vpx [VP8/VP9/VP10 encoder]?"}
        aom {Write-Output "Build aom [Alliance for Open Media codec]?"}
        rav1e {Write-Output "Build rav1e [Alternative, faster AV1 standalone encoder]?"}
        dav1d {Write-Output "Build dav1d [Alternative, faster AV1 decoder]?"}
        x2643 {Write-Output "Build x264 [H.264 encoder]?"}
        x2652 {Write-Output "Build x265 [H.265 encoder]?"}
        other265 {Write-Output "Build Kvazaar [H.265 encoder]?"}
        vvc {Write-Output "Build Fraunhofer VVC [H.265 successor enc/decoder]?"}
        flac {Write-Output "Build FLAC [Free Lossless Audio Codec]?"}
        fdkaac {Write-Output "Build FDK-AAC library and binary [AAC-LC/HE/HEv2 codec]?"}
        faac {Write-Output "Build FAAC library and binary [old, low-quality and nonfree AAC-LC codec]?"}
        mediainfo {Write-Output "Build mediainfo binaries [Multimedia file information tool]?"}
        soxB {Write-Output "Build sox binaries [Sound processing tool]?"}
        ffmpegB2 {Write-Output "Build FFmpeg binaries and libraries:"}
        ffmpegUpdate {Write-Output "Always build FFmpeg when libraries have been updated?"}
        ffmpegChoice {Write-Output "Choose ffmpeg and mpv optional libraries?"}
        mp4box {Write-Output "Build static mp4box [mp4 muxer/toolbox] binary?"}
        rtmpdump {Write-Output "Build static rtmpdump binaries [rtmp tools]?"}
        mplayer2 {Write-Output "######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################`n`nBuild static mplayer/mencoder binary?"}
        mpv {Write-Output "Build mpv?"}
        bmx {Write-Output "Build static bmx tools?"}
        curl {Write-Output "Build static curl?"}
        ffmbc {Write-Output "######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################`n`nBuild FFMedia Broadcast binary?"}
        cyanrip2 {Write-Output "Build cyanrip (CLI CD ripper)?"}
        redshift {Write-Output "Build redshift [f.lux FOSS clone]?"}
        ripgrep {Write-Output "Build ripgrep [faster grep in Rust]?"}
        jq {Write-Output "Build jq (CLI JSON processor)?"}
        dssim {Write-Output "Build dssim (multiscale SSIM in Rust)?"}
        cores {Write-Output "Number of CPU Cores/Threads for compiling:`n[it is non-recommended to use all cores/threads!]`n"}
        deleteSource {Write-Output "Delete versioned source folders after compile is done?"}
        strip {Write-Output "Strip compiled files binaries?"}
        pack {Write-Output "Pack compiled files?"}
        logging {Write-Output "Write logs of compilation commands?"}
        updateSuite {Write-Output "Create script to update suite files automatically?"}
        copybin {Write-Output "Copy final binary files to another folder?"}
    }
    switch -Regex ($Question) {
        arch {Write-Output "1 = both [32 bit and 64 bit]`n2 = 32 bit build system`n3 = 64 bit build system`n"}
        license2 {Write-Output "1 = Non-free [unredistributable, but can include anything]`n2 = GPLv3 [disables OpenSSL and FDK-AAC]`n3 = GPLv2.1 [Same disables as GPLv3 with addition of gmp, opencore codecs]`n4 = LGPLv3 [Disables x264, x265, XviD, GPL filters, etc.`n   but reenables OpenSSL/FDK-AAC]`n5 = LGPLv2.1 [same disables as LGPLv3 + GPLv2.1]`n`nIf building for yourself, it's OK to choose non-free.`nIf building to redistribute online, choose GPL or LGPL.`nIf building to include in a GPLv2.1 binary, choose LGPLv2.1 or GPLv2.1.`nIf you want to use FFmpeg together with closed source software, choose LGPL`nand follow instructions in https://www.ffmpeg.org/legal.html`n`nOpenSSL and FDK-AAC have licenses incompatible with GPL but compatible`nwith LGPL, so they won't be disabled automatically if you choose LGPL.`n"}
        x2643 {Write-Output "1 = Lib/binary with 8 and 10-bit`n2 = No`n3 = Lib/binary with only 10-bit`n4 = Lib/binary with 8 and 10-bit, and libavformat and ffms2`n5 = Shared lib/binary with 8 and 10-bit`n6 = Same as 4 with video codecs only (can reduce size by ~3MB)`n7 = Lib/binary with only 8-bit`n"}
        x2652 {Write-Output "1 = Lib/binary with Main, Main10 and Main12`n2 = No`n3 = Lib/binary with Main10 only`n4 = Lib/binary with Main only`n5 = Lib/binary with Main, shared libs with Main10 and Main12`n6 = Same as 1 with XP support and non-XP compatible x265-numa.exe`n7 = Lib/binary with Main12 only`n"}
        ffmpegB2 {Write-Output "1 = Yes [static] [recommended]`n2 = No`n3 = Shared`n4 = Both static and shared [shared goes to an isolated directory]`n5 = Shared-only with some shared libs (libass, freetype and fribidi)`n`nNote: Option 5 differs from 3 in that libass, freetype and fribidi are`ncompiled shared so they take less space. This one isn't tested a lot and`nwill fail with fontconfig enabled.`n"}
        ffmpegUpdate {Write-Output "1 = Yes`n2 = No`n3 = Only build FFmpeg/mpv and missing dependencies`n`nFFmpeg is updated a lot so you only need to select this if you`nabsolutely need updated external libraries in FFmpeg.`n"}
        ffmpegChoice {Write-Output "1 = Yes`n2 = No (Light build)`n3 = No (Mimic Zeranoe)`n4 = No (All available external libs)`n`nAvoid the last two unless you're really want useless libraries you'll never use.`nJust because you can include a shitty codec no one uses doesn't mean you should.`n`nIf you select yes, we will create files with the default options`nwe use with FFmpeg and mpv. You can remove any that you don't need or prefix`nthem with #`n"}
        mpv {Write-Output "1 = Yes`n2 = No`n3 = compile with Vapoursynth, if installed [see Warning]`n`nNote: when built with shared-only FFmpeg, mpv is also shared.`nNote: Requires at least Windows Vista.`nWarning: the third option isn't completely static. There's no way to include`na library dependant on Python statically. All users of the compiled binary`nwill need VapourSynth installed using the official package to even open mpv!`n"}
        curl {Write-Output "1 = Yes [same backend as FFmpeg's]`n2 = No`n3 = SChannel backend`n4 = GnuTLS backend`n5 = OpenSSL backend`n6 = LibreSSL backend`n7 = mbedTLS backend`n`nA curl-ca-bundle.crt will be created to be used as trusted certificate store`nfor all backends except SChannel.`n"}
        cores {Write-Output "Recommended: $(switch ([int]($env:NUMBER_OF_PROCESSORS / 2)) {0 {1} Default {$_}})`n"}
        "deleteSource|strip|logging" {Write-Output "1 = Yes [recommended]`n2 = No`n"}
        pack {Write-Output "1 = Yes`n2 = No [recommended]`n"}
        Default {Write-Output "1 = Yes`n2 = No`n"}
    }
    switch -Regex ($Question) {
        "vpx|aom|x2652" {Write-Output "Binaries being built depends on 'standalone=y'`n"}
        "dav1d|x2643" {Write-Output "Binaries being built depends on 'standalone=y' and are always static.`n"}
        fdkaac {Write-Output "Note: FFmpeg's aac encoder is no longer experimental and considered equal or`nbetter in quality from 96kbps and above. It still doesn't support AAC-HE/HEv2`nso if you need that or want better quality at lower bitrates than 96kbps,`nuse FDK-AAC.`n"}
        mplayer2 {Write-Output "Don't bother opening issues about this if it breaks, I don't fucking care`nabout ancient unmaintained shit code. One more issue open about this that`nisn't the suite's fault and mplayer goes fucking out.`n"}
        ffmbc {Write-Output "Note: this is a fork of FFmpeg 0.10. As such, it's very likely to fail`nto build, work, might burn your computer, kill your children, like mplayer.`nOnly enable it if you absolutely need it. If it breaks, complain first to`nthe author in #ffmbc in Freenode IRC.`n"}
        deleteSource {Write-Output "This will save a bit of space for libraries not compiled from git/hg/svn.`n"}
        Strip {Write-Output "Makes binaries smaller at only a small time cost after compiling.`n"}
        pack {Write-Output "Attention: Some security applications may detect packed binaries as malware.`nIncreases delay on runtime during which files need to be unpacked.`nMakes binaries smaller at a big time cost after compiling and on runtime.`nIf distributing the files, consider packing them with 7-zip instead.`n"}
        logging {Write-Output "Note: Setting this to yes will also hide output from these commands.`nOn successful compilation, these logs are deleted since they aren't needed.`n"}
        updateSuite {Write-Output "If you have made changes to the scripts, they will be reset but saved to`na .diff text file inside $build`n"}
        copybin {Write-Output "Will only copy the files within the local64|local32\bin* folders.`nIt is up to you to either set the install directory to a folder in `$env:PATH`n or add the install dir to `$env:PATH`n"}
    }
    Write-Output "$("-"*80)`n$("-"*80)"
    $jsonObjects.$Question = [int](
        Read-Host -Prompt $(
            switch ($Question) {
                arch {"Build System: "}
                license2 {"FFmpeg license: "}
                standalone {"Build standalone binaries: "}
                vpx2 {"Build vpx: "}
                x2643 {"Build x264: "}
                x2652 {"Build x265: "}
                other265 {"Build kvazaar: "}
                soxB {"Build sox: "}
                ffmpegB2 {"Build FFmpeg: "}
                ffmpegUpdate {"Build ffmpeg if lib is new: "}
                ffmpegChoice {"Choose ffmpeg and mpv optional libs: "}
                mplayer2 {"Build mplayer: "}
                cyanrip2 {"Build cyanrip: "}
                cores {"Core/Thread Count: "}
                deleteSource {"Delete source: "}
                strip {"Strip files: "}
                pack {"Pack files: "}
                logging {"Write logs: "}
                updateSuite {"Create update script: "}
                copybin {"Copy binary files: "}
                Default {"Build $($Question): "}
            }
        )
    )
    ConvertTo-Json -InputObject $jsonObjects | Out-File $json
    if ($jsonObjects.ffmpegChoice -eq 1) {
        function Write-Option ($inp) {
            foreach ($opt in $inp.split(" ")) {
                if ($opt -match '^--|^#--') {
                    Write-Output "$opt"
                } elseif ($opt.StartsWith("#")) {
                    Write-Output "#--enable-$($opt.Substring(1))"
                } else {
                    Write-Output "--enable-$opt"
                }
            }
        }
        $ffmpegoptions = "$build\ffmpeg_options.txt"
        if ((($jsonObjects.ffmpegB2 -ne 2) -or ($jsonObjects.cyanrip2 -eq 1)) -and !(Test-Path -PathType Leaf $ffmpegoptions) -and ($Question -eq "ffmpegB2")) {
            $(
                Write-Output "# Lines starting with this character are ignored`n# Basic built-in options, can be removed if you delete '--disable-autodetect'"
                Write-Option $ffmpeg_options_builtin
                Write-Output "# Common options"
                Write-Option $ffmpeg_options_basic
                Write-Output "# Zeranoe"
                Write-Option $ffmpeg_options_zeranoe
                Write-Output "# Full"
                Write-Option $ffmpeg_options_full
            ) | Out-File $ffmpegoptions
            Write-Output "$("-"*80)`nFile with default FFmpeg options has been created in $ffmpegoptions`n`nEdit it now or leave it unedited to compile according to defaults.`n$("-"*80)"
            Pause
        }
        $mpvoptions = "$build\mpv_options.txt"
        if (($jsonObjects.mpv -eq 1) -and !(Test-Path -PathType Leaf $mpvoptions) -and ($Question -eq "ffmpegB2")) {
            $(
                Write-Output "# Lines starting with this character are ignored`n`n# Built-in options, use --disable- to disable them."
                Write-Option $mpv_options_builtin
                Write-Output "`n# Common options or overriden defaults"
                Write-Option $mpv_options_basic
                Write-Output "`n# Full"
                Write-Option $mpv_options_full
            ) | Out-File $mpvoptions
            Write-Output "$("-"*80)`nFile with default mpv options has been created in $mpvoptions`n`nEdit it now or leave it unedited to compile according to defaults.`n$("-"*80)"
            Pause
        }
    }
}

foreach ($a in $jsonObjects.psobject.Properties.Name) {
    if ($a -NotMatch "installdir") {
        while (1..$(
                switch -Regex ($a) {
                    "arch|ffmpegUpdate|mpv" {3}
                    "license2|ffmpegB2" {5}
                    "x2643|x2652|curl" {7}
                    ffmpegChoice {4}
                    cores {999}
                    Default {2}
                }
            ) -notcontains $jsonObjects.$a) {
            Write-Question -Question $a
        }
    }
}
foreach ($a in $jsonObjects.psobject.Properties.Name) {
    switch ($a) {
        msys2Arch {
            $msys2 = switch ([System.IntPtr]::Size) {
                4 {"msys32"}
                default {"msys64"}
            }
        }
        arch {
            $build32 = switch ($jsonObjects.arch) {
                1 {"yes"}
                2 {"yes"}
                Default {"no"}
            }
            $build64 = switch ($jsonObjects.arch) {
                1 {"yes"}
                3 {"yes"}
                Default {"no"}
            }
        }
        license2 {
            $license2 = switch ($jsonObjects.license2) {
                1 {"nonfree"}
                2 {"gplv3"}
                3 {"gpl"}
                4 {"lgplv3"}
                5 {"lgpl"}
            }
        }
        x2643 {
            $x2643 = switch ($jsonObjects.x2643) {
                1 {"yes"}
                2 {"no"}
                3 {"high"}
                4 {"full"}
                5 {"shared"}
                6 {"fullv"}
                7 {"o8"}
            }
        }
        x2652 {
            $x2652 = switch ($jsonObjects.x2652) {
                1 {"y"}
                2 {"n"}
                3 {"o10"}
                4 {"o8"}
                5 {"s"}
                6 {"d"}
                7 {"o12"}
            }
        }
        ffmpegB2 {
            $ffmpeg = switch ($jsonObjects.ffmpegB2) {
                1 {"static"}
                2 {"no"}
                3 {"shared"}
                4 {"both"}
                5 {"sharedlibs"}
            }
        }
        ffmpegUpdate {
            $ffmpegUpdate = switch ($jsonObjects.ffmpegUpdate) {
                1 {"y"}
                2 {"n"}
                3 {"onlyFFmpeg"}
            }
        }
        ffmpegChoice {
            $ffmpegChoice = switch ($jsonObjects.ffmpegChoice) {
                1 {"y"}
                2 {"n"}
                3 {"z"}
                4 {"f"}
            }
        }
        mpv {
            $mpv = switch ($jsonObjects.mpv) {
                1 {"y"}
                2 {"n"}
                3 {"z"}
            }
        }
        curl {
            $curl = switch ($jsonObjects.curl) {
                1 {"y"}
                2 {"n"}
                3 {"schannel"}
                4 {"gnutls"}
                5 {"openssl"}
                6 {"libressl"}
                7 {"mbedtls"}
            }
        }
        installdir {
            if ($jsonObjects.copybin -eq 1) {
                try {
                    $installdir = Resolve-Path $(New-Item -Force -ItemType Directory -Path $jsonObjects.installdir)
                } catch {
                    do {
                        Write-Output "$("-"*80)`n$("-"*80)`n`nWhere do you want to install the final programs?`nChoose an empty directory else you will have a lot of random files within that folder`nEnter a full path such as:`n`"C:\test\`"`n`n$("-"*80)`n$("-"*80)"
                        $jsonObjects.installdir = [string]((Read-Host -Prompt "Path to final dir: ").Replace('"', ''))
                        $installdir = Resolve-Path $(New-Item -Force -ItemType Directory -Path $jsonObjects.installdir)
                    } while (!(Test-Path -IsValid -Path $jsonObjects.installdir))
                }
                ConvertTo-Json -InputObject $jsonObjects | Out-File $json
            }
        }
        Default {
            Set-Variable -Name $($a) -Value $(
                switch ($jsonObjects.$a) {
                    1 {"y"}
                    2 {"n"}
                }
            )
        }
    }
}
# EOQuestions
if ($PSVersionTable.PSVersion.Major -ne 4) {Write-Output "$("-"*60)`nIf you want to reuse this console do`n`$env:Path = [System.Environment]::GetEnvironmentVariable(`"Path`", `"Machine`") + `";`" + [System.Environment]::GetEnvironmentVariable(`"Path`", `"User`")`n$("-"*60)"}
$msys2Path = "$PSScriptRoot\$msys2"
$env:Path = $($env:Path.Split(';') -match "NVIDIA|Windows" -join ';') + ";$msys2Path\usr\bin"
$msysprefix = switch ([System.IntPtr]::Size) {
    4 {"i686"}
    Default {"x86_64"}
}

if (!(Test-Path $msys2Path\msys2_shell.cmd)) {
    Set-Location $build
    Write-Output "$("-"*60)`n`n- Download and install msys2 basic system`n`n$("-"*60)"
    try {
        if ((Test-Path $env:TEMP\msys2-base.tar.xz) -and ((Get-Item $env:TEMP\msys2-base.tar.xz).Length -eq (Invoke-WebRequest -Uri "http://repo.msys2.org/distrib/msys2-$($msysprefix)-latest.tar.xz" -UseBasicParsing -Method Head).headers.'Content-Length')) {
        } else {
            Remove-Item $env:TEMP\msys2-base.tar.xz -ErrorAction Ignore
            Invoke-WebRequest -OutFile $env:TEMP\msys2-base.tar.xz -Uri "http://repo.msys2.org/distrib/msys2-$($msysprefix)-latest.tar.xz"
        }
        Copy-Item $env:TEMP\msys2-base.tar.xz $build\msys2-base.tar.xz
        if (!(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -name Version -ErrorAction Ignore | Select-Object -Property PSChildName, Version | Where-Object {$_.PSChildName -match "Client"} | Where-Object {$_.Version -ge 4.5})) {
            Write-Output "You lack a dotnet version greater than or equal to 4.5, thus this script cannot automatically extract the msys2 system"
            Write-Output "Please upgrade your dotnet either by updating your OS or by downloading the latest version at:"
            Write-Output "https://dotnet.microsoft.com/download/dotnet-framework-runtime"
            exit 3
        }
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile((Invoke-RestMethod "https://www.powershellgallery.com/api/v2/Packages?`$filter=Id eq 'pscx' and IsLatestVersion").content.src, "$build\pscx.zip")
        Add-Type -assembly "System.IO.Compression.FileSystem"
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$build\pscx.zip", "$build\pscx")
        Remove-Item -Recurse $PWD\pscx.zip, $PWD\pscx\_rels, $PWD\pscx\package
        powershell -noprofile -command {
            Import-Module -Name $PWD\pscx\Pscx.psd1 -Force -Cmdlet Expand-Archive -Prefix 7za
            Expand-7zaArchive -Force -ShowProgress $PWD\msys2-base.tar.xz
            Expand-7zaArchive -Force -ShowProgress -OutputPath .. $PWD\msys2-base.tar
        }
        Remove-Item -Recurse $PWD\pscx, $PWD\msys2-base.tar, $PWD\msys2-base.tar.xz
    } catch {
        Write-Output "$("-"*60)`n`n- Download msys2 basic system failed,`n- please download it manually from:`n- http://repo.msys2.org/distrib/`n- and copy the uncompressed folder to:`n- $build`n- and start the script again!`n`n$("-"*60)"
        pause
        exit
    }
}

$fstab = Resolve-Path $msys2Path\etc\fstab
$bash = (Resolve-Path $msys2Path\usr\bin\bash.exe).ProviderPath
# createFolders
function Write-BaseFolders ([int]$bit) {
    if (!(Test-Path -Path $PSScriptRoot\local$bit\bin-global -PathType Container)) {
        Write-Output "$("-"*60)`ncreating $bit-bit install folders`n$("-"*60)"
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin -ErrorAction Ignore | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-audio -ErrorAction Ignore | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-global -ErrorAction Ignore | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-video -ErrorAction Ignore | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\etc -ErrorAction Ignore | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\include -ErrorAction Ignore | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\lib\pkgconfig -ErrorAction Ignore | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\share -ErrorAction Ignore | Out-Null
    }
}

function Write-Fstab {
    Write-Output "$("-"*60)`n`n- write fstab mount file`n`n$("-"*60)"
    $fstabtext = "none / cygdrive binary,posix=0,noacl,user 0 0`n$PSScriptRoot\ /trunk`n$PSScriptRoot\build\ /build`n$msys2Path\mingw32\ /mingw32`n$msys2Path\mingw64\ /mingw64`n"
    if ($build32 -eq "yes") {$fstabtext += "$PSScriptRoot\local32\ /local32`n"}
    if ($build64 -eq "yes") {$fstabtext += "$PSScriptRoot\local64\ /local64`n"}
    New-Item -Force -ItemType File -Path $fstab -Value $fstabtext | Out-Null
}
function Write-Log ([string]$logfile, [switch]$Script, [ScriptBlock]$ScriptBlock, [switch]$commandbash, [string]$BashCommand) {
    try {
        Start-Transcript -Force -Path $logfile | Out-Null
        if ($Script) {
            &$ScriptBlock
        }
        if ($commandbash) {
            &$bash @($BashCommand.Split(' '))
        }
    } catch {
        Write-Output "Stopping log and exiting"
    } finally {
        Stop-Transcript | Out-Null
        Get-ChildItem -File -Include *.log -Path $build | ForEach-Object {Set-Content -Path $_.fulllname -Value $(Get-Content $_.fullname | Where-Object {$_ -notmatch "Username|RunAs|Machine|Host Application"})}
    }
}

if ($build64 -eq "yes") {Write-BaseFolders -bit 64}
if ($build32 -eq "yes") {Write-BaseFolders -bit 32}
if (!(Test-Path $PSScriptRoot\mintty.lnk)) {
    Set-Location $msys2Path
    if ($msys2 -eq "msys32") {
        Write-Output "$("-"*60)`n`nrebase $msys2 system`n`n$("-"*60)"
        Start-Process -Wait -NoNewWindow -FilePath $msys2Path\autorebase.bat
    }
    Write-Log -logfile $build\firstrun.log -Script -ScriptBlock {Write-Output "$("-"*60)`n- make a first run`n$("-"*60)"} -commandbash -bashcommand "-lc exit"
    Write-Fstab
    Write-Log -logfile $build\firstUpdate.log -Script -ScriptBlock {Write-Output "$("-"*60)`nFirst update`n$("-"*60)"} -commandbash -bashcommand "-lc 'pacman -Sy --needed --ask=20 --noconfirm --asdeps pacman-mirrors'"
    Write-Log -logfile $build\criticalUpdate.log -Script -ScriptBlock {Write-Output "$("-"*60)`ncritical updates`n$("-"*60)"} -commandbash -bashcommand "-lc 'pacman -Sy --needed --ask=20 --noconfirm --asdeps pacman-mirrors'"
    Write-Log -logfile $build\secondUpdate.log -Script -ScriptBlock {Write-Output "$("-"*60)`nsecond update`n$("-"*60)"} -commandbash -bashcommand "-lc 'pacman -Syu --needed --ask=20 --noconfirm --asdeps'"
    $link = $(New-Object -ComObject WScript.Shell).CreateShortcut("$PSScriptRoot\mintty.lnk")
    $link.TargetPath = "$msys2Path\msys2_shell.cmd"
    $link.Arguments = "-full-path -mingw"
    $link.Description = "msys2 shell console"
    $link.WindowStyle = 1
    $link.IconLocation = "$msys2Path\msys2.ico"
    $link.WorkingDirectory = "$msys2Path"
    $link.Save()
}
if (!(Test-Path $fstab) -or (($build32 -eq "yes") -and !(Select-String -Pattern "local32" -Path $fstab)) -or (($build64 -eq "yes") -and !(Select-String -Pattern "local64" -Path $fstab)) -or (($build32 -eq "no") -and (Select-String -Pattern "local32" -Path $fstab)) -or (($build64 -eq "no") -and (Select-String -Pattern "local64" -Path $fstab)) -or !(Select-String -Path $fstab -Pattern "trunk") -or ((Select-String -Path $fstab -Pattern "trunk") -NotMatch ($PSScriptRoot -replace "\\", "\\"))) {Write-Fstab}
if (!(Test-Path "$msys2Path\home\$env:UserName\.minttyrc")) {New-Item -ItemType File -Force -Path $msys2Path\home\$env:UserName\.minttyrc -Value "Locale=en_US`nCharset=UTF-8`nFont=Consolas`nColumns=120`nRows=30" | Out-Null}
if (!(Test-Path "$msys2Path\home\$env:UserName\.hgrc")) {New-Item -Force -ItemType File -Path $msys2Path\home\$env:UserName\.hgrc -Value "[ui]`nusername = $env:UserName`nverbose = True`neditor = vim`n`n[web]`ncacerts=/usr/ssl/cert.pem`n`n[extensions]`ncolor =`n`n[color]`nstatus.modified = magenta bold`nstatus.added = green bold`nstatus.removed = red bold`nstatus.deleted = cyan bold`nstatus.unknown = blue bold`nstatus.ignored = black bold" | Out-Null}
if (!(Test-Path $msys2Path\home\$env:UserName\.gitconfig)) {New-Item -Force -ItemType File -Path $msys2Path\home\$env:UserName\.gitconfig -Value "[user]`nname = $env:UserName`nemail = $env:UserName@$env:COMPUTERNAME`n`n[color]`nui = true`n`n[core]`neditor = vim`nautocrlf =`n`n[merge]`ntool = vimdiff`n`n[push]`ndefault = simple" | Out-Null}

Remove-Item $msys2Path\etc\pac-base.pk -Force -ErrorAction Ignore
foreach ($i in $msyspackages) {Write-Output "$i" | Out-File -Append $msys2Path\etc\pac-base.pk}

if (!(Test-Path $msys2Path\usr\bin\make.exe)) {
    Remove-Item -Force $build\install_base_failed -ErrorAction Ignore
    New-Item -Force -ItemType File -Path $msys2Path\etc\pac-base.temp -Value $($msyspackages | ForEach-Object {"$_"} | Out-String) | Out-Null
    (Get-Content $msys2Path\etc\pac-base.temp -Raw).Replace("`r", "") | Set-Content $msys2Path\etc\pac-base.temp -Force -NoNewline
    Write-Log -logfile $build\pacman.log -Script -ScriptBlock {Write-Output "$("-"*60)`ninstall msys2 base system`n$("-"*60)"}  -commandbash -bashcommand "-lc 'pacman -Sw --noconfirm --ask=20 --needed - < /etc/pac-base.temp; pacman -S --noconfirm --ask=20 --needed - < /etc/pac-base.temp'"
    Remove-Item $msys2Path\etc\pac-base.temp -ErrorAction Ignore
}

if (!(Test-Path $msys2Path\usr\ssl\cert.pem)) {Write-Log -logfile $build\cert.log -commandbash -BashCommand "-lc update-ca-trust"}
if (!(Test-Path "$msys2Path\usr\bin\hg.bat")) {New-Item -Force -ItemType File -Path $msys2Path\usr\bin\hg.bat -Value "`@echo off`r`n`r`nsetlocal`r`nset HG=%~f0`r`n`r`nset PYTHONHOME=`r`nset in=%*`r`nset out=%in: {= `"{%`r`nset out=%out:} =}`" %`r`n`r`n%~dp0python2 %~dp0hg %out%" | Out-Null}

Remove-Item -Force $msys2Path\etc\pac-mingw.pk -ErrorAction Ignore
foreach ($i in $mingwpackages) {Write-Output "$i" | Out-File -Append $msys2Path\etc\pac-mingw.pk}

function Get-Compiler ([int]$bit) {
    New-Item -Force -ItemType File -Path $msys2Path\etc\pac-mingw.temp -Value $($mingwpackages | ForEach-Object {"mingw-w64-$(switch ($bit) {64 {"x86_64"} 32 {"i686"}})-$_"} | Out-String) | Out-Null
    (Get-Content $msys2Path\etc\pac-mingw.temp -Raw).Replace("`r", "") | Set-Content $msys2Path\etc\pac-mingw.temp -Force -NoNewline
    Write-Log -logfile $build\mingw$($bit).log -Script -ScriptBlock {Write-Output "$("-"*60)`ninstall $bit bit compiler`n$("-"*60)"} -commandbash -BashCommand "-lc 'pacman -Sw --noconfirm --ask=20 --needed - < /etc/pac-mingw.temp; pacman -S --noconfirm --ask=20 --needed - < /etc/pac-mingw.temp'"
    if (!(Test-Path $msys2Path\mingw$($bit)\bin\gcc.exe)) {
        Write-Output "$("-"*60)`nMinGW$($bit) GCC compiler isn't installed; maybe the download didn't work`nDo you want to try it again?`n$("-"*60)"
        if ($(Read-Host -Prompt "try again [y/n]: ") -eq "y") {Get-Compiler -bit $bit} else {exit}
    } else {
        Remove-Item $msys2Path\etc\pac-mingw.temp -ErrorAction Ignore
    }
}
if (($build32 -eq "yes") -and !(Test-Path $msys2Path\mingw32\bin\gcc.exe)) {Get-Compiler -bit 32}
if (($build64 -eq "yes") -and !(Test-Path $msys2Path\mingw64\bin\gcc.exe)) {Get-Compiler -bit 64}

# updatebase
Write-Output "$("-"*60)`nupdate autobuild suite`n$("-"*60)"
"compile", "helper", "update" | ForEach-Object {if (!(Test-Path $build\media-suite_$($_).sh)) {Invoke-WebRequest -OutFile $build\media-suite_$($_).sh -Uri "https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/media-suite_$($_).sh"}}

$updatescript = $(
    Write-Output "#!/bin/bash`n`n# Run this file by dragging it to mintty shortcut.`n# Be sure the suite is not running before using it!`n`nupdate=yes`n"
    Get-Content $build\media-suite_update.sh | Select-Object -Index ($((Select-String -Path $build\media-suite_update.sh -Pattern "start suite update").LineNumber)..$((Select-String -Path $build\media-suite_update.sh -Pattern "end suite update").LineNumber)) | ForEach-Object {$_ + "`n"}
) | Out-String -NoNewline
if (($jsonObjects.updateSuite -eq 1) -and ((Get-FileHash -Path $PSScriptRoot\update_suite.sh -ErrorAction Ignore).Hash -ne (Get-FileHash -InputStream ([IO.memorystream]::new([text.encoding]::utf8.getbytes($updatescript))))).hash) {
    Write-Output "$("-"*60)`nCreating suite update file...`n`nRun this file by dragging it to mintty before the next time you run`nthe suite and before reporting an issue.`n`nIt needs to be run separately and with the suite not running!`n$("-"*60)"
    New-Item -Path $PSScriptRoot\update_suite.sh -ItemType File -Value $updatescript
}

# update
try {
    switch ($PSVersionTable.PSVersion.Major) {
        6 {if (((Test-Connection -ComputerName pool.sks-keyservers.net -Count 1 -ErrorAction Ignore -InformationAction Ignore).Replies.RoundTripTime) -eq 0) {throw}}
        Default {if (!(Test-Connection -ComputerName pool.sks-keyservers.net -Count 1 -InformationAction Ignore -ErrorAction Ignore).ResponseTime) {throw}}
    }
} catch {
    Write-Output "Can't connect to sks-keyservers, exiting"
    exit
}
try {
    switch ($PSVersionTable.PSVersion.Major) {
        6 {if (((Test-Connection -ComputerName github.com -Count 1 -ErrorAction Ignore -InformationAction Ignore).Replies.RoundTripTime) -eq 0) {throw}}
        Default {if (!(Test-Connection -ComputerName github.com -Count 1 -InformationAction Ignore -ErrorAction Ignore).ResponseTime) {throw}}
    }
} catch {
    Write-Output "Can't connect to github, exiting"
    exit
}
Write-Log -logfile $build\update.log -commandbash -BashCommand "-l /build/media-suite_update.sh --build32=$build32 --build64=$build64"
if (Test-Path $build\update_core) {
    Write-Log -logfile $build\update_core.log -Script -ScriptBlock {Write-Output "$("-"*60)`ncritical updates`n$("-"*60)"} -commandbash -BashCommand "-lc 'pacman -Syyu --needed --noconfirm --ask=20 --asdeps'"
    Remove-Item $build\update_core
}
if ($msys2 -eq "msys32") {
    Write-Output "$("-"*60)`nsecond rebase $msys2 system`n$("-"*60)"
    Start-Process -Wait -NoNewWindow -FilePath $msys2Path\autorebase.bat
}

function Write-Profile ([int]$bit) {
    New-Item -Force -ItemType File -Path $PSScriptRoot\local$($bit)\etc\profile2.local -Value "MSYSTEM=MINGW$bit`nsource /etc/msystem`n`n# package build directory`nLOCALBUILDDIR=/build`n# package installation prefix`nLOCALDESTDIR=/local$bit`nexport LOCALBUILDDIR LOCALDESTDIR`n`nbits='$($bit)bit'`n`nalias dir='ls -la --color=auto'`nalias ls='ls --color=auto'`nexport CC=gcc`n`nCARCH=`"$msysprefix`"`nCPATH=`"``cygpath -m `$LOCALDESTDIR/include``;``cygpath -m `$MINGW_PREFIX/include```"`nLIBRARY_PATH=`"``cygpath -m `$LOCALDESTDIR/lib``;``cygpath -m `$MINGW_PREFIX/lib```"`nexport CPATH LIBRARY_PATH`n`nMANPATH=`"`$`{LOCALDESTDIR`}/share/man:`$`{MINGW_PREFIX`}/share/man:/usr/share/man`"`nINFOPATH=`"`$`{LOCALDESTDIR`}/share/info:`$`{MINGW_PREFIX`}/share/info:/usr/share/info`"`n`nDXSDK_DIR=`"`$`{MINGW_PREFIX`}/`$`{MINGW_CHOST`}`"`nACLOCAL_PATH=`"`$`{LOCALDESTDIR`}/share/aclocal:`$`{MINGW_PREFIX`}/share/aclocal:/usr/share/aclocal`"`nPKG_CONFIG=`"`$`{MINGW_PREFIX`}/bin/pkg-config --static`"`nPKG_CONFIG_PATH=`"`$`{LOCALDESTDIR`}/lib/pkgconfig:`$`{MINGW_PREFIX`}/lib/pkgconfig`"`nCPPFLAGS=`"-D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1`"`nCFLAGS=`"-mthreads -mtune=generic -O2 -pipe`"`nCXXFLAGS=`"`$`{CFLAGS`}`"`nLDFLAGS=`"-pipe -static-libgcc -static-libstdc++`"`nexport DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM`n`nexport CARGO_HOME=`"/opt/cargo`" RUSTUP_HOME=`"/opt/cargo`"`n`nexport PYTHONPATH=`n`nLANG=en_US.UTF-8`nPATH=`"`$`{LOCALDESTDIR`}/bin:`$`{MINGW_PREFIX`}/bin:`$`{INFOPATH`}:`$`{MSYS2_PATH`}:`$`{ORIGINAL_PATH`}`"`nPATH=`"`$`{LOCALDESTDIR`}/bin-audio:`$`{LOCALDESTDIR`}/bin-global:`$`{LOCALDESTDIR`}/bin-video:`$`{PATH`}`"`nPATH=`"/opt/cargo/bin:/opt/bin:`$`{PATH`}`"`nsource '/etc/profile.d/perlbin.sh'`nPS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '`nHOME=`"/home/`$`{USERNAME`}`"`nGIT_GUI_LIB_DIR=``cygpath -w /usr/share/git-gui/lib```nexport LANG PATH PS1 HOME GIT_GUI_LIB_DIR`nstty susp undef`ncd /trunk`ntest -f `"`$LOCALDESTDIR/etc/custom_profile`" && source `"`$LOCALDESTDIR/etc/custom_profile`"`n" | Out-Null
}
if ($build32 -eq "yes") {Write-Profile -bit 32}
if ($build64 -eq "yes") {Write-Profile -bit 64}

if (Test-Path $msys2Path\etc\profile.pacnew) {Move-Item -Force $msys2Path\etc\profile.pacnew $msys2Path\etc\profile}
if (!(Select-String -Pattern "profile2.local" -Path $msys2Path\etc\profile)) {New-Item -Force -ItemType File -Path $msys2Path\etc\profile.d\Zab-suite.sh -Value "if [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW64 ]]; then`n   source /local64/etc/profile2.local`nelif [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW32 ]]; then`n   source /local32/etc/profile2.local`nfi" | Out-Null}

# compileLocals
Set-Location $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "MABSbat"
Remove-Item $env:TEMP\msys2-base.tar.xz -ErrorAction Ignore
$env:MSYSTEM = switch ($build64) {
    yes {"MINGW64"}
    Default {"MINGW32"}
}
$env:MSYS2_PATH_TYPE = "inherit"
Write-Log -logfile $build\compile.log -commandbash -BashCommand "-l /build/media-suite_compile.sh --cpuCount=$cores --build32=$build32 --build64=$build64 --deleteSource=$deleteSource --mp4box=$mp4box --vpx=$vpx2 --x264=$x2643 --x265=$x2652 --other265=$other265 --flac=$flac --fdkaac=$fdkaac --mediainfo=$mediainfo --sox=$soxB --ffmpeg=$ffmpeg --ffmpegUpdate=$ffmpegUpdate --ffmpegChoice=$ffmpegChoice --mplayer=$mplayer2 --mpv=$mpv --license=$license2 --stripping=$strip --packing=$pack --rtmpdump=$rtmpdump --logging=$logging --bmx=$bmx --standalone=$standalone --aom=$aom --faac=$faac --ffmbc=$ffmbc --curl=$curl --cyanrip=$cyanrip2 --redshift=$redshift --rav1e=$rav1e --ripgrep=$ripgrep --dav1d=$dav1d --vvc=$vvc --jq=$jq --dssim=$dssim"

if ($copybin -eq "y") {
    $bits = switch ($build64) {
        "yes" {"64"}
        default {"32"}
    }
    Write-Output "Copying files to $installdir"
    Get-ChildItem -Recurse -Path $PSScriptRoot\local$($bits)\bin-*\* | ForEach-Object {
        $testfile = $_
        function Invoke-Copy {
            try {
                Copy-Item -Path $testfile -Destination $installdir
            } catch [System.IO.IOException] {
                Write-Output "$testfile is in use or is running. Do you wish to skip copying this file?"
                [validateset("y*", "n*")]$skip = Read-Host -Prompt "Skip [y/n]: "
                if ($skip -match "y*") {
                    continue
                } else {
                    if (($testfile.Extension -eq ".exe") -and ((Get-Process).Path -match $testfile.FullName.Replace('\', '\\'))) {
                        Write-Output "Do you want to force quit $($testfile.BaseName)?"
                        [validateset("y*", "n*")]$forcequit = Read-Host -Prompt "Skip [y/n]: "
                        if ($forcequit -match "y*") {
                            Get-Process | Where-Object {$_.Path -match $testfile.FullName.Replace('\', '\\')} | Stop-Process
                        } else {
                            Write-Output "Press [Enter] when the program is finished."
                            pause
                        }
                        Invoke-Copy
                    }
                    if (($testfile.Extension -eq ".dll") -and (Get-Process -Module -ErrorAction Ignore | Select-Object -Property FileName | Select-String -Pattern $testfile.FullName.Replace('\', '\\'))) {
                        Write-Output "$testfile is still in use. Since it is a dll, this script is unable to truly help you.`nPlease close whatever program could be using it and press [Enter]."
                        pause
                        Invoke-Copy
                    }
                }
            } catch {
                Write-Output "An Unknown Error occured. Not related to systemIO.`nCheck the Powershellerror.txt at the suite's basefolder and see if you can find out what's wrong."
                $Error | Out-File $PSScriptRoot\Powershellerror.txt
            }
        }
    }
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")