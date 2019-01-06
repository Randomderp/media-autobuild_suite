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
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-----------------------------------------------------------------------------
#>

if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "Your Powershell version is too low!"
    Write-Host "Please update your version either through an OS upgrade"
    Write-Host "or download the latest version for your system from"
    Write-Host "https://github.com/PowerShell/PowerShell"
    Pause
    exit
}
#requires -Version 3.0.0
$Host.UI.RawUI.WindowTitle = "media-autobuild_suite"
$PSDefaultParameterValues["Out-File:Encoding"] = "UTF8"

if ($PSScriptRoot -match " ") {
    Write-Host "$("-"*70)"
    Write-Host "You have probably run the script in a path with spaces.`n"
    Write-Host "This is not supported.`n"
    Write-Host "Please move the script to use a path without spaces. Example:`n"
    Write-Host "Incorrect: C:\build suite\`n"
    Write-Host "Correct:   C:\build_suite\`n"
    Pause
    exit
} elseif ($PSScriptRoot.Length -gt 60) {
    Write-Host "$("-"*70)"
    Write-Host "The total filepath to the suite seems too large (larger than 60 characters):`n"
    Write-Host "$PSScriptRoot`n"
    Write-Host "Some packages might fail building because of it.`n"
    Write-Host "Please move the suite directory closer to the root of your drive and maybe`n"
    Write-Host "rename the suite directory to a smaller name. Examples:`n"
    Write-Host "Avoid:  C:\Users\Administrator\Desktop\testing\media-autobuild_suite-master`n"
    Write-Host "Prefer: C:\media-autobuild_suite`n"
    Write-Host "Prefer: C:\ab-suite`n"
    pause
    exit
} else {
    Set-Location $PSScriptRoot
}

# Set Build path
New-Item -ItemType Directory -Force -Path $PSScriptRoot\build -ErrorAction Ignore | Out-Null
$build = Resolve-Path $PSScriptRoot\build
$json = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$build\media-autobuild_suite.json")

# Set package variables
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
    msys2Arch    = switch ([System.IntPtr]::Size) {
        4 {1}
        default {2}
    }
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
    ffmpegChoice = 0
    mp4box       = 0
    rtmpdump     = 0
    mplayer2     = 0
    mpv          = 0
    bmx          = 0
    curl         = 0
    ffmbc        = 0
    cyanrip2     = 0
    redshift     = 0
    ripgrep      = 0
    jq           = 0
    cores        = 0
    deleteSource = 0
    strip        = 0
    pack         = 0
    logging      = 0
    updateSuite  = 0
}

function Write-Questions ($Question) {
    Write-Host "$("-"*80)`n$("-"*80)`n"
    switch ($Question) {
        arch {Write-Host "Select the build target system:"}
        license2 {Write-Host "Build FFmpeg with which license?"}
        standalone {Write-host "Build standalone binaries for libraries included in FFmpeg?`neg. Compile opusenc.exe if --enable-libopus"}
        vpx2 {Write-Host "Build vpx [VP8/VP9/VP10 encoder]?"}
        aom {Write-Host "Build aom [Alliance for Open Media codec]?"}
        rav1e {Write-host "Build rav1e [Alternative, faster AV1 standalone encoder]?"}
        dav1d {Write-Host "Build dav1d [Alternative, faster AV1 decoder]?"}
        x2643 {Write-host "Build x264 [H.264 encoder]?"}
        x2652 {Write-host "Build x265 [H.265 encoder]?"}
        other265 {Write-Host "Build standalone Kvazaar [H.265 encoder]?"}
        vvc {Write-Host "Build Fraunhofer VVC [H.265 successor enc/decoder]?"}
        flac {Write-Host "Build FLAC [Free Lossless Audio Codec]?"}
        fdkaac {Write-Host "Build FDK-AAC library and binary [AAC-LC/HE/HEv2 codec]?"}
        faac {Write-Host "Build FAAC library and binary [old, low-quality and nonfree AAC-LC codec]?"}
        mediainfo {Write-Host "Build mediainfo binaries [Multimedia file information tool]?"}
        soxB {Write-Host "Build sox binaries [Sound processing tool]?"}
        ffmpegB2 {Write-host "Build FFmpeg binaries and libraries:"}
        ffmpegUpdate {Write-host "Always build FFmpeg when libraries have been updated?"}
        ffmpegChoice {Write-host "Choose ffmpeg and mpv optional libraries?"}
        mp4box {Write-Host "Build static mp4box [mp4 muxer/toolbox] binary?"}
        rtmpdump {Write-Host "Build static rtmpdump binaries [rtmp tools]?"}
        mplayer2 {Write-Host "######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################`n`nBuild static mplayer/mencoder binary?"}
        mpv {Write-host "Build mpv?"}
        bmx {Write-Host "Build static bmx tools?"}
        curl {Write-host "Build static curl?"}
        ffmbc {Write-Host "######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################`n`nBuild FFMedia Broadcast binary?"}
        cyanrip2 {Write-Host "Build cyanrip (CLI CD ripper)?"}
        redshift {Write-Host "Build redshift [f.lux FOSS clone]?"}
        ripgrep {Write-Host "Build ripgrep [faster grep in Rust]?"}
        jq {Write-Host "Build jq (CLI JSON processor)?"}
        cores {Write-Host "Number of CPU Cores/Threads for compiling:`n[it is non-recommended to use all cores/threads!]`n"}
        deleteSource {Write-Host "Delete versioned source folders after compile is done?"}
        strip {Write-Host "Strip compiled files binaries?"}
        pack {Write-Host "Pack compiled files?"}
        logging {Write-Host "Write logs of compilation commands?"}
        updateSuite {Write-Host "Create script to update suite files automatically?"}
    }
    switch -Regex ($Question) {
        arch {
            Write-Host "1 = both [32 bit and 64 bit]"
            Write-Host "2 = 32 bit build system"
            Write-Host "3 = 64 bit build system`n"
        }
        license2 {
            Write-Host "1 = Non-free [unredistributable, but can include anything]"
            Write-Host "2 = GPLv3 [disables OpenSSL and FDK-AAC]"
            Write-Host "3 = GPLv2.1 [Same disables as GPLv3 with addition of gmp, opencore codecs]"
            Write-Host "4 = LGPLv3 [Disables x264, x265, XviD, GPL filters, etc."
            Write-Host "   but reenables OpenSSL/FDK-AAC]"
            Write-Host "5 = LGPLv2.1 [same disables as LGPLv3 + GPLv2.1]`n"
            Write-Host "If building for yourself, it's OK to choose non-free."
            Write-Host "If building to redistribute online, choose GPL or LGPL."
            Write-Host "If building to include in a GPLv2.1 binary, choose LGPLv2.1 or GPLv2.1."
            Write-Host "If you want to use FFmpeg together with closed source software, choose LGPL"
            Write-Host "and follow instructions in https://www.ffmpeg.org/legal.html`n"
            Write-Host "OpenSSL and FDK-AAC have licenses incompatible with GPL but compatible"
            Write-Host "with LGPL, so they won't be disabled automatically if you choose LGPL.`n"
        }
        x2643 {
            Write-host "1 = Lib/binary with 8 and 10-bit"
            Write-host "2 = No"
            Write-host "3 = Lib/binary with only 10-bit"
            Write-host "4 = Lib/binary with 8 and 10-bit, and libavformat and ffms2"
            Write-host "5 = Shared lib/binary with 8 and 10-bit"
            Write-host "6 = Same as 4 with video codecs only ^(can reduce size by ~3MB^)"
            Write-host "7 = Lib/binary with only 8-bit`n"
        }
        x2652 {
            Write-host "1 = Lib/binary with Main, Main10 and Main12"
            Write-host "2 = No"
            Write-host "3 = Lib/binary with Main10 only"
            Write-host "4 = Lib/binary with Main only"
            Write-host "5 = Lib/binary with Main, shared libs with Main10 and Main12"
            Write-host "6 = Same as 1 with XP support and non-XP compatible x265-numa.exe"
            Write-host "7 = Lib/binary with Main12 only`n"
        }
        ffmpegB2 {
            Write-host "1 = Yes [static] [recommended]"
            Write-host "2 = No"
            Write-host "3 = Shared"
            Write-host "4 = Both static and shared [shared goes to an isolated directory]"
            Write-host "5 = Shared-only with some shared libs (libass, freetype and fribidi)`n"
            Write-host "Note: Option 5 differs from 3 in that libass, freetype and fribidi are"
            Write-host "compiled shared so they take less space. This one isn't tested a lot and"
            Write-host "will fail with fontconfig enabled.`n"
        }
        ffmpegUpdate {
            Write-host "1 = Yes"
            Write-host "2 = No"
            Write-host "3 = Only build FFmpeg/mpv and missing dependencies`n"
            Write-host "FFmpeg is updated a lot so you only need to select this if you"
            Write-host "absolutely need updated external libraries in FFmpeg.`n"
        }
        ffmpegChoice {
            Write-host "1 = Yes"
            Write-host "2 = No (Light build)"
            Write-host "3 = No (Mimic Zeranoe)"
            Write-host "4 = No (All available external libs)`n"
            Write-host "Avoid the last two unless you're really want useless libraries you'll never use."
            Write-host "Just because you can include a shitty codec no one uses doesn't mean you should.`n"
            Write-host "If you select yes, we will create files with the default options"
            Write-host "we use with FFmpeg and mpv. You can remove any that you don't need or prefix"
            Write-host "them with #`n"
        }
        mpv {
            Write-host "1 = Yes"
            Write-host "2 = No"
            Write-host "3 = compile with Vapoursynth, if installed [see Warning]`n"
            Write-host "Note: when built with shared-only FFmpeg, mpv is also shared."
            Write-host "Note: Requires at least Windows Vista."
            Write-host "Warning: the third option isn't completely static. There's no way to include"
            Write-host "a library dependant on Python statically. All users of the compiled binary"
            Write-host "will need VapourSynth installed using the official package to even open mpv!`n"
        }
        curl {
            Write-host "1 = Yes [same backend as FFmpeg's]"
            Write-host "2 = No"
            Write-host "3 = SChannel backend"
            Write-host "4 = GnuTLS backend"
            Write-host "5 = OpenSSL backend"
            Write-host "6 = LibreSSL backend"
            Write-host "7 = mbedTLS backend`n"
            Write-host "A curl-ca-bundle.crt will be created to be used as trusted certificate store"
            Write-host "for all backends except SChannel.`n"
        }
        cores {
            Write-Host "Recommended: $(switch ((Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors) {
                        1 {1}
                        Default {(Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors / 2}
                    })`n"
        }
        "deleteSource|strip|logging" {
            Write-host "1 = Yes [recommended]"
            Write-host "2 = No`n"
        }
        pack {
            Write-host "1 = Yes"
            Write-host "2 = No [recommended]`n"
        }
        Default {
            Write-host "1 = Yes"
            Write-host "2 = No`n"
        }
    }
    switch -Regex ($Question) {
        "vpx|aom|x2652" {Write-host "Binaries being built depends on 'standalone=y'`n"}
        "dav1d|x2643" {Write-host "Binaries being built depends on 'standalone=y' and are always static.`n"}
        fdkaac {
            Write-host "Note: FFmpeg's aac encoder is no longer experimental and considered equal or"
            Write-host "better in quality from 96kbps and above. It still doesn't support AAC-HE/HEv2"
            Write-host "so if you need that or want better quality at lower bitrates than 96kbps,"
            Write-host "use FDK-AAC.`n"
        }
        mplayer2 {
            Write-host "Don't bother opening issues about this if it breaks, I don't fucking care"
            Write-host "about ancient unmaintained shit code. One more issue open about this that"
            Write-host "isn't the suite's fault and mplayer goes fucking out.`n"
        }
        ffmbc {
            Write-host "Note: this is a fork of FFmpeg 0.10. As such, it's very likely to fail"
            Write-host "to build, work, might burn your computer, kill your children, like mplayer."
            Write-host "Only enable it if you absolutely need it. If it breaks, complain first to"
            Write-host "the author in #ffmbc in Freenode IRC.`n"
        }
        deleteSource {Write-Host "This will save a bit of space for libraries not compiled from git/hg/svn.`n"}
        Strip {Write-Host "Makes binaries smaller at only a small time cost after compiling.`n"}
        pack {
            Write-Host "Attention: Some security applications may detect packed binaries as malware."
            Write-Host "Increases delay on runtime during which files need to be unpacked."
            Write-Host "Makes binaries smaller at a big time cost after compiling and on runtime."
            Write-Host "If distributing the files, consider packing them with 7-zip instead.`n"
        }
        logging {
            Write-Host "Note: Setting this to yes will also hide output from these commands."
            Write-Host "On successful compilation, these logs are deleted since they aren't needed.`n"
        }
        updateSuite {
            Write-Host "If you have made changes to the scripts, they will be reset but saved to"
            Write-Host "a .diff text file inside $build`n"
        }
    }
    Write-Host "$("-"*80)`n$("-"*80)"
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
                Default {"Build $($Question): "}
            }
        )
    )
    ConvertTo-Json -InputObject $jsonObjects | Out-File $json
}

if (Test-Path -Path $json) {
    $jsonProperties = Get-Content $json | ConvertFrom-Json
    foreach ($a in $jsonProperties.psobject.Properties.Name) {
        if ($jsonProperties.$a -ne 0) {
            $jsonObjects.$a = $jsonProperties.$a
        }
    }
} else {
    $jsonObjects | ConvertTo-Json | Out-File $json
}

# sytemVars
foreach ($a in $jsonObjects.psobject.Properties.Name) {
    while (1..$(switch -Regex ($a) {
                "arch|ffmpegUpdate|mpv" {3}
                "license2|ffmpegB2" {5}
                "x2643|x2652|curl" {7}
                ffmpegChoice {4}
                cores {999}
                Default {2}
            }) -notcontains $jsonObjects.$a) {
        Write-Questions -Question $a
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
            function Write-Option ([array]$inp) {
                foreach ($opt in $inp) {
                    if (($opt | Out-String).StartsWith("--")) {
                        Write-Output $opt
                    } elseif (($opt | Out-String).StartsWith("#--")) {
                        Write-Output $opt
                    } elseif (($opt | Out-String).StartsWith("#")) {
                        $opta = ($opt | Out-String -NoNewline).Substring(1)
                        Write-Output "#--enable-$opta"
                    } else {
                        Write-Output "--enable-$opt"
                    }
                }
            }
            $ffmpegoptions = "$build\ffmpeg_options.txt"
            $mpvoptions = "$build\mpv_options.txt"
            switch ($jsonObjects.ffmpegChoice) {
                1 {
                    $ffmpegChoice = "y"
                    if (!(Test-Path -PathType Leaf $ffmpegoptions)) {
                        Write-Output "# Lines starting with this character are ignored`n# Basic built-in options, can be removed if you delete '--disable-autodetect'" | Out-File $ffmpegoptions
                        Write-Option $ffmpeg_options_builtin | Out-File -Append $ffmpegoptions
                        Write-Output "# Common options" | Out-File -Append $ffmpegoptions
                        Write-Option $ffmpeg_options_basic | Out-File -Append $ffmpegoptions
                        Write-Output "# Zeranoe" | Out-File -Append $ffmpegoptions
                        Write-Option $ffmpeg_options_zeranoe | Out-File -Append $ffmpegoptions
                        Write-Output "# Full" | Out-File -Append $ffmpegoptions
                        Write-Option $ffmpeg_options_full | Out-File -Append $ffmpegoptions
                        Write-Host "$("-"*80)"
                        Write-Host "File with default FFmpeg options has been created in $ffmpegoptions`n"
                        Write-Host "Edit it now or leave it unedited to compile according to defaults."
                        Write-Host "$("-"*80)"
                        Pause
                    }
                    if (!(Test-Path -PathType Leaf $mpvoptions)) {
                        Write-Output "# Lines starting with this character are ignored`n`n# Built-in options, use --disable- to disable them." | Out-File $mpvoptions
                        Write-Option $mpv_options_builtin | Out-File -Append $mpvoptions
                        Write-Output "`n# Common options or overriden defaults" | Out-File -Append $mpvoptions
                        Write-Option $mpv_options_basic | Out-File -Append $mpvoptions
                        Write-Output "`n# Full" | Out-File -Append $mpvoptions
                        Write-Option $mpv_options_full | Out-File -Append $mpvoptions
                        Write-Host "$("-"*80)"
                        Write-Host "File with default mpv options has been created in $mpvoptions`n"
                        Write-Host "Edit it now or leave it unedited to compile according to defaults."
                        Write-Host "$("-"*80)"
                        Pause
                    }

                }
                2 {$ffmpegChoice = "n"}
                3 {$ffmpegChoice = "z"}
                4 {$ffmpegChoice = "f"}
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
        cyanrip2 {
            $cyanrip2 = switch ($jsonObjects.cyanrip2) {
                1 {"yes"}
                2 {"no"}
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
Write-Host "$("-"*60)"
if ($PSVersionTable.PSVersion.Major -ne 3) {
    Write-Host "If you want to reuse this console do"
    Write-Host "`$env:Path = `$Global:TempPath"
    Write-Host "else you won't have your original path in this console until you close and reopen."
}
Write-Host "If you use control+C at any time durring the script, make sure to run"
Write-Host "Get-Job | Remove-Job -Force"
Write-Host "$("-"*60)"
Start-Sleep -Seconds 2
# Temporarily store the Path
$Global:TempPath = $env:Path
$env:Path = $($Global:TempPath.Split(';') -match "NVIDIA|Windows" -join ';') + ";$PSScriptRoot\msys64\usr\bin"
$msys2Path = "$PSScriptRoot\$msys2"
$bash = "$msys2Path\usr\bin\bash.exe"
$msysprefix = switch ([System.IntPtr]::Size) {
    4 {"i686"}
    Default {"x86_64"}
}

if (!(Test-Path $msys2Path\msys2_shell.cmd)) {
    Set-Location $build
    if (!(Test-Path $build\7za.exe)) {
        Write-Host "$("-"*60)`n`n- Downloading Wget`n`n$("-"*60)"
        $progressPreference = 'silentlyContinue'
        if (Test-Connection -Quiet -ComputerName i.fsbn.eu -Count 1 -InformationAction Ignore) {
            Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://i.fsbn.eu/pub/wget-pack.exe"
        } elseif (Test-Connection -Quiet -ComputerName randomderp.com -Count 1 -InformationAction Ignore) {
            Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://randomderp.com/wget-pack.exe"
        } else {
            Write-Host "$("-"*60)`n"
            Write-Host "Script to download necessary components failed.`n"
            Write-Host "Download and extract this manually to inside $($build):"
            Write-Host "https://i.fsbn.eu/pub/wget-pack.exe`n"
            Write-Host "$("-"*60)"
            Pause
            exit
        }
        $progressPreference = 'Continue'
        $stream = ([IO.StreamReader]$((Resolve-Path $build\wget-pack.exe).ProviderPath)).BaseStream
        if (( -Join ([Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash($stream) | ForEach-Object {"{0:x2}" -f $_})) -eq "3F226318A73987227674A4FEDDE47DF07E85A48744A07C7F6CDD4F908EF28947") {
            Start-Process -NoNewWindow -Wait -FilePath $build\wget-pack.exe  -WorkingDirectory $build
        } else {
            $stream.Close()
            Remove-Item $build\wget-pack.exe
            Write-Host "$("-"*60)`n"
            Write-Host "Script to download necessary components failed.`n"
            Write-Host "Download and extract this manually to inside $($build):"
            Write-Host "https://i.fsbn.eu/pub/wget-pack.exe`n"
            Write-Host "$("-"*60)"
            Pause
            exit
        }
        $stream.Close()
        Remove-Item $build\wget-pack.exe
    }
    Write-Host "$("-"*60)`n`n- Download and install msys2 basic system`n`n$("-"*60)"
    $iteration = 0
    function Get-Msys2 ([switch]$failed) {
        if ($failed) {
            if ($iteration -le 2) {
                $iteration += 1
                Write-Host "Msys2 base download/extraction failed! Redownloading and trying again."
            } else {
                Write-Host "$("-"*60)`n"
                Write-Host "- Download msys2 basic system failed,"
                Write-Host "- please download it manually from:"
                Write-Host "- http://repo.msys2.org/distrib/"
                Write-Host "- and copy the uncompressed folder to:"
                Write-Host "- $build"
                Write-Host "- and start the batch script again!`n"
                Write-Host "$("-"*60)"
                pause
                exit
            }
        }
        Remove-Item $build\msys2-base.tar.xz -ErrorAction Ignore
        Remove-Item $build\msys2-base.tar -ErrorAction Ignore
        Invoke-WebRequest -OutFile $build\msys2-base.tar.xz -Uri "http://repo.msys2.org/distrib/msys2-$($msysprefix)-latest.tar.xz"
        if (Test-Path $build\msys2-base.tar.xz) {
            Invoke-Expression "$build\7za.exe x -aoa msys2-base.tar.xz"
            if (-not $? -or $LASTEXITCODE -ne 0) {Get-Msys2 -failed}
            Remove-Item $build\msys2-base.tar.xz -ErrorAction Ignore
            Invoke-Expression "$build\7za.exe x -aoa msys2-base.tar -o.."
            if (-not $? -or $LASTEXITCODE -ne 0) {Get-Msys2 -failed}
            Remove-Item $build\msys2-base.tar
        } else {
            Get-Msys2 -failed
        }
    }
    Get-Msys2
    if (!(Test-Path $PSScriptRoot\$msys2\usr\bin\msys-2.0.dll)) {
        Write-Host "$("-"*60)`n"
        Write-Host "- Download msys2 basic system failed,"
        Write-Host "- please download it manually from:"
        Write-Host "- http://repo.msys2.org/distrib/"
        Write-Host "- and copy the uncompressed folder to:"
        Write-Host "- $build"
        Write-Host "- and start the batch script again!`n"
        Write-Host "$("-"*60)"
        pause
        exit
    }
}

# createFolders
function Write-BaseFolders ([int]$bit) {
    Write-Host "$("-"*60)`ncreating $bit-bit install folders`n$("-"*60)"
    New-Item -ItemType Directory $PSScriptRoot\local$bit\bin -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-audio -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-global -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-video -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory $PSScriptRoot\local$bit\etc -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory $PSScriptRoot\local$bit\include -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory $PSScriptRoot\local$bit\lib\pkgconfig -ErrorAction Ignore | Out-Null
    New-Item -ItemType Directory $PSScriptRoot\local$bit\share -ErrorAction Ignore | Out-Null
}
if ($build64 -eq "yes") {Write-BaseFolders -bit 64}
if ($build32 -eq "yes") {Write-BaseFolders -bit 32}
$fstab = Resolve-Path $msys2Path\etc\fstab
# checkFstab
function Write-Fstab {
    Write-Host "$("-"*60)`n`n- write fstab mount file`n`n$("-"*60)"
    $(
        Write-Output "none / cygdrive binary,posix=0,noacl,user 0 0`n"
        Write-Output "$PSScriptRoot\ /trunk`n"
        Write-Output "$PSScriptRoot\build\ /build`n"
        Write-Output "$msys2Path\mingw32\ /mingw32`n"
        Write-Output "$msys2Path\mingw64\ /mingw64`n"
    ) | Out-File -NoNewline -Force $fstab
    if ($build32 -eq "yes") {Write-Output "$PSScriptRoot\local32\ /local32" | Out-File -NoNewline -Append $fstab}
    if ($build64 -eq "yes") {Write-Output "$PSScriptRoot\local64\ /local64" | Out-File -NoNewline -Append $fstab}
}

#$CR = ([char[]] (3, 0, 2, 3, 1)) -join ''

if (!(Test-Path $PSScriptRoot\mintty.lnk)) {
    Set-Location $msys2Path
    if ($msys2 -eq "msys32") {
        Write-Host "$("-"*60)`n`nrebase $msys2 system`n`n$("-"*60)"
        Start-Process -Wait -NoNewWindow -FilePath $msys2Path\autorebase.bat
    }
    Write-Output "$("-"*60)`n- make a first run`n$("-"*60)" | Tee-Object $build\firstrun.log
    Invoke-Expression "$bash -lc exit" | Tee-Object -Append $build\firstrun.log
    Write-Fstab
    Write-Output "$("-"*60)`nFirst update`n$("-"*60)" | Tee-Object $build\firstUpdate.log
    Invoke-Expression "$bash -lc 'pacman -S --needed --ask=20 --noconfirm --asdeps pacman-mirrors ca-certificates'"  | Tee-Object -Append $build\firstUpdate.log
    Write-Output "$("-"*60)`ncritical updates`n$("-"*60)" | Tee-Object $build\criticalUpdate.log
    Invoke-Expression "$bash -lc 'pacman -Syyu --needed --ask=20 --noconfirm --asdeps '"  | Tee-Object -Append $build\criticalUpdate.log
    Write-Output "$("-"*60)`nsecond update`n$("-"*60)" | Tee-Object $build\secondUpdate.log
    Invoke-Expression "$bash -lc 'pacman -Syyu --needed --ask=20 --noconfirm --asdeps'"  | Tee-Object  -Append $build\secondUpdate.log
    # equivalent to setlink.vbs
    $wshShell = New-Object -ComObject WScript.Shell
    $link = $wshShell.CreateShortcut("$PSScriptRoot\mintty.lnk")
    $link.TargetPath = "$msys2Path\msys2_shell.cmd"
    $link.Arguments = "-full-path -mingw"
    $link.Description = "msys2 shell console"
    $link.WindowStyle = 1
    $link.IconLocation = "$msys2Path\msys2.ico"
    $link.WorkingDirectory = "$msys2Path"
    $link.Save()
}
if (!(Test-Path $fstab) -or (($build32 -eq "yes") -and !(Select-String -Pattern "local32" -Path $fstab)) -or (($build64 -eq "yes") -and !(Select-String -Pattern "local64" -Path $fstab)) -or (($build32 -eq "no") -and (Select-String -Pattern "local32" -Path $fstab)) -or (($build64 -eq "no") -and (Select-String -Pattern "local64" -Path $fstab)) -or !(Select-String -Path $fstab -Pattern "trunk") -or (((Select-String -Path $fstab -Pattern "trunk").Line.Split(' ')[0] -ne $PSScriptRoot))) {
    Write-Fstab
}
if (!(Invoke-Expression "$bash -lc 'pacman-key -f EFD16019AE4FF531'" )) {
    Write-Host "$("-"*60)`nForcefully signing abrepo key`n$("-"*60)"
    Invoke-Expression "$bash -lc 'pacman-key -r EFD16019AE4FF531; pacman-key --lsign EFD16019AE4FF531'"
}

if (!(Test-Path "$msys2Path\home\$env:UserName\.minttyrc")) {
    Write-Output "Locale=en_US`nCharset=UTF-8`nFont=Consolas`nColumns=120`nRows=30" | Out-File -NoNewline -Force $msys2Path\home\$env:UserName\.minttyrc
}
if (!(Test-Path "$msys2Path\home\$env:UserName\.hgrc")) {
    [System.IO.File]::WriteAllText("$msys2Path\home\$env:UserName\.hgrc", "[ui]`nusername = $env:UserName`nverbose = True`neditor = vim`n`n[web]`ncacerts=/usr/ssl/cert.pem`n`n[extensions]`ncolor =`n`n[color]`nstatus.modified = magenta bold`nstatus.added = green bold`nstatus.removed = red bold`nstatus.deleted = cyan bold`nstatus.unknown = blue bold`nstatus.ignored = black bold`n")

}

if (!(Test-Path $msys2Path\home\$env:UserName\.gitconfig)) {
    [System.IO.File]::WriteAllText("$msys2Path\home\$env:UserName\.gitconfig",
        "[user]`nname = $env:UserName`nemail = $env:UserName@$env:COMPUTERNAME`n`n[color]`nui = true`n`n[core]`neditor = vim`nautocrlf =`n`n[merge]`ntool = vimdiff`n`n[push]`ndefault = simple`n")
}

Remove-Item $msys2Path\etc\pac-base.pk -Force -ErrorAction Ignore
foreach ($i in $msyspackages) {Write-Output "$i" | Out-File -Append $msys2Path\etc\pac-base.pk}

if (!(Test-Path $msys2Path\usr\bin\make.exe)) {
    Write-Output "$("-"*60)`ninstall msys2 base system`n$("-"*60)" | Tee-Object $build\pacman.log
    Remove-Item -Force $build\install_base_failed -ErrorAction Ignore
    [System.IO.File]::WriteAllText("$msys2Path\etc\pac-base.temp", $($msyspackages | ForEach-Object {"$_"} | Out-String))
    (Get-Content $msys2Path\etc\pac-base.temp -Raw).Replace("`r`n", "`n") | Set-Content $msys2Path\etc\pac-base.temp -Force -NoNewline
    Invoke-Expression "$bash -lc 'cat /etc/pac-base.temp | pacman -Sw --noconfirm --ask=20 --needed - ; cat /etc/pac-base.temp | pacman -S --noconfirm --ask=20 --needed - ; cat /etc/pac-base.temp | pacman -D --asexplicit --noconfirm --ask=20 -'"  | Tee-Object $build\pacman.log
    Remove-Item $msys2Path\etc\pac-base.temp -ErrorAction Ignore
}

Remove-Item -Force $build\cert.log -ErrorAction Ignore
Invoke-Expression "$bash -lc update-ca-trust"  | Tee-Object $build\cert.log

if (!(Test-Path "$msys2Path\usr\bin\hg.bat")) {
    Write-Output "`@echo off`r`n`r`nsetlocal`r`nset HG=%~f0`r`n`r`nset PYTHONHOME=`r`nset in=%*`r`nset out=%in: {= `"{%`r`nset out=%out:} =}`" %`r`n`r`n%~dp0python2 %~dp0hg %out%`r`n" | Out-File -Force -NoNewline $msys2Path\usr\bin\hg.bat
}

Remove-Item -Force $msys2Path\etc\pac-mingw.pk -ErrorAction Ignore
foreach ($i in $mingwpackages) {Write-Output "$i" | Out-File -Append $msys2Path\etc\pac-mingw.pk}

function Get-Compiler ([int]$bit) {
    Write-Host "$("-"*60)`ninstall $bit bit compiler`n$("-"*60)" | Tee-Object $build\mingw$($bit).log
    [System.IO.File]::WriteAllText("$msys2Path\etc\pac-mingw.temp", $($mingwpackages | ForEach-Object {"mingw-w64-$($msysprefix)-$_"} | Out-String))
    (Get-Content $msys2Path\etc\pac-mingw.temp -Raw).Replace("`r`n", "`n") | Set-Content $msys2Path\etc\pac-mingw.temp -Force -NoNewline
    Invoke-Expression "$bash -lc 'cat /etc/pac-mingw.temp | pacman -Sw --noconfirm --ask=20 --needed -; cat /etc/pac-mingw.temp | pacman -S --noconfirm --ask=20 --needed - ; cat /etc/pac-mingw.temp | pacman -D --asexplicit --noconfirm --ask=20 -'"  | Tee-Object -Append $build\mingw$($bit).log
    if (!(Test-Path $msys2Path\mingw$($bit)\bin\gcc.exe)) {
        Write-Host "$("-"*60)`nMinGW$($bit) GCC compiler isn't installed; maybe the download didn't work`nDo you want to try it again?`n$("-"*60)"
        if ($(Read-Host -Prompt "try again [y/n]: ") -eq "y") {
            Get-Compiler -bit $bit
        } else {
            exit
        }
    } else {
        Remove-Item $msys2Path\etc\pac-mingw.temp -ErrorAction Ignore
    }
}
if (($build32 -eq "yes") -and !(Test-Path $msys2Path\mingw32\bin\gcc.exe)) {Get-Compiler -bit 32}
if (($build64 -eq "yes") -and !(Test-Path $msys2Path\mingw64\bin\gcc.exe)) {Get-Compiler -bit 64}

# updatebase
Write-Host "$("-"*60)`nupdate autobuild suite`n$("-"*60)"
$scripts = "compile", "helper", "update"
foreach ($s in $scripts) {
    if (!(Test-Path $build\media-suite_$($s).sh)) {
        Invoke-WebRequest -OutFile $build\media-suite_$($s).sh -Uri "https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/media-suite_$($s).sh"
    }
}
if ($jsonObjects.updateSuite -eq 1) {
    Write-Host "$("-"*60)"
    Write-Host "Creating suite update file...`n"
    Write-Host "Run this file by dragging it to mintty before the next time you run"
    Write-Host "the suite and before reporting an issue.`n"
    Write-Host "It needs to be run separately and with the suite not running!"
    Write-Host "$("-"*60)"
    $(
        Write-Output "#!/bin/bash`n`n# Run this file by dragging it to mintty shortcut.`n# Be sure the suite is not running before using it!`n`nupdate=yes`n"
        Get-Content $build\media-suite_update.sh | Select-Object -Index ($((Select-String -Path $build\media-suite_update.sh -Pattern "start suite update").LineNumber)..$((Select-String -Path $build\media-suite_update.sh -Pattern "end suite update").LineNumber)) | ForEach-Object {$_ + "`n"}
    ) | Out-File -NoNewline -Force $PSScriptRoot\update_suite.sh
}

# update
Remove-Item -Force $build\update.log -ErrorAction Ignore
Invoke-Expression "$bash -lc 'pacman -D --asexplicit --noconfirm --ask=20 mintty; pacman -D --asdep --noconfirm --ask=20 bzip2 findutils getent gzip inetutils lndir msys2-keyring msys2-launcher-git pactoys-git pax-git tftp-hpa tzcode which'"
Invoke-Expression "$bash -lc 'echo no | /build/media-suite_update.sh --build32=$build32 --build64=$build64'"  | Tee-Object $build\update.log
if (Test-Path $build\update_core) {
    Write-Output "$("-"*60)`ncritical updates`n$("-"*60)" | Tee-Object $build\update_core.log
    Invoke-Expression "$bash -lc 'pacman -Syyu --needed --noconfirm --ask=20 --asdeps'" | -Append Tee-Object $build\update_core.log
    Remove-Item $build\update_core
}

if ($msys2 -eq "msys32") {
    Write-Host "$("-"*60)`nsecond rebase $msys2 system`n$("-"*60)"
    Start-Process -NoNewWindow -Wait -FilePath $msys2Path\autorebase.bat
}
# Write config profiles
function Write-Profile ([int]$bit) {
    [System.IO.File]::WriteAllText("$PSScriptRoot\local$($bit)\etc\profile2.local", "MSYSTEM=MINGW$bit`nsource /etc/msystem`n`n# package build directory`nLOCALBUILDDIR=/build`n# package installation prefix`nLOCALDESTDIR=/local$bit`nexport LOCALBUILDDIR LOCALDESTDIR`n`nbits='$($bit)bit'`n`nalias dir='ls -la --color=auto'`nalias ls='ls --color=auto'`nexport CC=gcc`n`nCARCH=`"$msysprefix`"`nCPATH=`"``cygpath -m `$LOCALDESTDIR/include``;``cygpath -m `$MINGW_PREFIX/include```"`nLIBRARY_PATH=`"``cygpath -m `$LOCALDESTDIR/lib``;``cygpath -m `$MINGW_PREFIX/lib```"`nexport CPATH LIBRARY_PATH`n`nMANPATH=`"`$`{LOCALDESTDIR`}/share/man:`$`{MINGW_PREFIX`}/share/man:/usr/share/man`"`nINFOPATH=`"`$`{LOCALDESTDIR`}/share/info:`$`{MINGW_PREFIX`}/share/info:/usr/share/info`"`n`nDXSDK_DIR=`"`$`{MINGW_PREFIX`}/`$`{MINGW_CHOST`}`"`nACLOCAL_PATH=`"`$`{LOCALDESTDIR`}/share/aclocal:`$`{MINGW_PREFIX`}/share/aclocal:/usr/share/aclocal`"`nPKG_CONFIG=`"`$`{MINGW_PREFIX`}/bin/pkg-config --static`"`nPKG_CONFIG_PATH=`"`$`{LOCALDESTDIR`}/lib/pkgconfig:`$`{MINGW_PREFIX`}/lib/pkgconfig`"`nCPPFLAGS=`"-D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1`"`nCFLAGS=`"-mthreads -mtune=generic -O2 -pipe`"`nCXXFLAGS=`"`$`{CFLAGS`}`"`nLDFLAGS=`"-pipe -static-libgcc -static-libstdc++`"`nexport DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM`n`nexport CARGO_HOME=`"/opt/cargo`" RUSTUP_HOME=`"/opt/cargo`"`n`nexport PYTHONPATH=`n`nLANG=en_US.UTF-8`nPATH=`"`$`{LOCALDESTDIR`}/bin:`$`{MINGW_PREFIX`}/bin:`$`{INFOPATH`}:`$`{MSYS2_PATH`}:`$`{ORIGINAL_PATH`}`"`nPATH=`"`$`{LOCALDESTDIR`}/bin-audio:`$`{LOCALDESTDIR`}/bin-global:`$`{LOCALDESTDIR`}/bin-video:`$`{PATH`}`"`nPATH=`"/opt/cargo/bin:/opt/bin:`$`{PATH`}`"`nsource '/etc/profile.d/perlbin.sh'`nPS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '`nHOME=`"/home/`$`{USERNAME`}`"`nGIT_GUI_LIB_DIR=``cygpath -w /usr/share/git-gui/lib```nexport LANG PATH PS1 HOME GIT_GUI_LIB_DIR`nstty susp undef`ncd /trunk`ntest -f `"`$LOCALDESTDIR/etc/custom_profile`" && source `"`$LOCALDESTDIR/etc/custom_profile`"`n")
}
if ($build32 -eq "yes") {Write-Profile -bit 32}
if ($build64 -eq "yes") {Write-Profile -bit 64}

# loginProfile
if (Test-Path $msys2Path\etc\profile.pacnew) {Move-Item -Force $msys2Path\etc\profile.pacnew $msys2Path\etc\profile}
if (!(Select-String -Pattern "profile2.local" -Path $msys2Path\etc\profile)) {
    [System.IO.File]::WriteAllText("$msys2Path\etc\profile.d\Zab-suite.sh", "if [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW64 ]]; then`n   source /local64/etc/profile2.local`nelif [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW32 ]]; then`n   source /local32/etc/profile2.local`nfi")
}

# compileLocals
$MSYSTEM = switch ($build32) {
    yes {"MINGW32"}
    Default {"MINGW64"}
}
Set-Location $PSScriptRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "MABSbat"
Start-Job -Name "Media-Autobuild_Suite Compile" -ArgumentList $msys2Path, $MSYSTEM, $build, $bash, $($jsonObjects.Cores), $build32, $build64, $deleteSource, $mp4box, $vpx2, $x2643, $x2652, $other265, $flac, $fdkaac, $mediainfo, $soxB, $ffmpeg, $ffmpegUpdate, $ffmpegChoice, $mplayer2, $mpv, $license2, $strip, $pack, $rtmpdump, $logging, $bmx, $standalone, $aom, $faac, $ffmbc, $curl, $cyanrip2, $redshift, $rav1e, $ripgrep, $dav1d, $vvc -ScriptBlock {
    param(
        $msys2Path,
        $MSYSTEM,
        $build,
        $bash,
        $cores,
        $build32,
        $build64,
        $deleteSource,
        $mp4box,
        $vpx2,
        $x2643,
        $x2652,
        $other265,
        $flac,
        $fdkaac,
        $mediainfo,
        $soxB,
        $ffmpeg,
        $ffmpegUpdate,
        $ffmpegChoice,
        $mplayer2,
        $mpv,
        $license2,
        $strip,
        $pack,
        $rtmpdump,
        $logging,
        $bmx,
        $standalone,
        $aom,
        $faac,
        $ffmbc,
        $curl,
        $cyanrip2,
        $redshift,
        $rav1e,
        $ripgrep,
        $dav1d,
        $vvc
    )
    Remove-Item -Force $build\compile.log -ErrorAction Ignore
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Invoke-Expression "$msys2Path\usr\bin\env MSYSTEM=$MSYSTEM MSYS2_PATH_TYPE=inherit /usr/bin/bash --login /build/media-suite_compile.sh --cpuCount=$cores --build32=$build32 --build64=$build64 --deleteSource=$deleteSource --mp4box=$mp4box --vpx=$vpx2 --x264=$x2643 --x265=$x2652 --other265=$other265 --flac=$flac --fdkaac=$fdkaac --mediainfo=$mediainfo --sox=$soxB --ffmpeg=$ffmpeg --ffmpegUpdate=$ffmpegUpdate --ffmpegChoice=$ffmpegChoice --mplayer=$mplayer2 --mpv=$mpv --license=$license2 --stripping=$strip --packing=$pack --rtmpdump=$rtmpdump --logging=$logging --bmx=$bmx --standalone=$standalone --aom=$aom --faac=$faac --ffmbc=$ffmbc --curl=$curl --cyanrip=$cyanrip2 --redshift=$redshift --rav1e=$rav1e --ripgrep=$ripgrep --dav1d=$dav1d --vvc=$vvc --jq=$jq"  | Tee-Object $build\compile.log
}
while (Get-Job -State Running) {Receive-Job -Name "Media-Autobuild_Suite Compile" | Out-Host}
$env:Path = $Global:TempPath