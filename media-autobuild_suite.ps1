#!/usr/bin/env powershell

#-----------------------------------------------------------------------------
# LICENSE --------------------------------------------------------------------
#-----------------------------------------------------------------------------
#  This Windows Batchscript is for setup a compiler environment for building
#  ffmpeg and other media tools under Windows.
#
#    Copyright (C) 2013  jb_alvarado
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------

# Some functions do not have any counter parts in ps version below 3, aka XP, 2003, 2008.
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
    Write-Host "----------------------------------------------------------------------"
    Write-Host "You have probably run the script in a path with spaces.`n"
    Write-Host "This is not supported.`n"
    Write-Host "Please move the script to use a path without spaces. Example:`n"
    Write-Host "Incorrect: C:\build suite\`n"
    Write-Host "Correct:   C:\build_suite\`n"
    Pause
    exit
}
elseif ($PSScriptRoot.Length -gt 60) {
    Write-Host "----------------------------------------------------------------------"
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
}
else {
    Set-Location $PSScriptRoot
}

# Set Build path
$build = "$PSScriptRoot\build"
New-Item -ItemType Directory -Force -Path $build | Out-Null
$json = "$build\media-autobuild_suite.json"

# Set package variables
$msyspackages = "asciidoc", "autoconf", "autoconf-archive", "autogen", "automake-wrapper", "bison", "diffstat", "dos2unix", "doxygen", "git", "gperf", "gyp-git", "help2man", "intltool", "itstool", "libtool", "make", "man-db", "mercurial", "mintty", "p7zip", "patch", "python", "ruby", "subversion", "texinfo", "unzip", "wget", "winpty", "xmlto", "zip"
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
        4 {
            1
        }
        default {
            2
        }
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
    cores        = 0
    deleteSource = 0
    strip        = 0
    pack         = 0
    logging      = 0
    updateSuite  = 0
}
<#
$order = @("msys2Arch", "arch", "license2", "standalone", "vpx2", "aom", "rav1e", "dav1d", "x2643", "x2652", "other265", "vvc", "flac", "fdkaac", "faac", "mediainfo", "soxB", "ffmpegB2", "ffmpegUpdate", "ffmpegChoice", "mp4box", "rtmpdump", "mplayer2", "mpv", "bmx", "curl", "ffmbc", "cyanrip2", "redshift", "ripgrep", "cores", "deleteSource", "strip", "pack", "logging", "updateSuite")
$order = [PSCustomObject]@{
    10 = "msys2Arch"
    11 = "arch"
    12 = "license2"
    13 = "standalone"
    14 = "vpx2"
    15 = "aom"
    16 = "rav1e"
    17 = "dav1d"
    18 = "x2643"
    19 = "x2652"
    20 = "other265"
    21 = "vvc"
    22 = "flac"
    23 = "fdkaac"
    24 = "faac"
    25 = "mediainfo"
    26 = "soxB"
    27 = "ffmpegB2"
    28 = "ffmpegUpdate"
    29 = "ffmpegChoice"
    30 = "mp4box"
    31 = "rtmpdump"
    32 = "mplayer2"
    33 = "mpv"
    34 = "bmx"
    35 = "curl"
    36 = "ffmbc"
    37 = "cyanrip2"
    38 = "redshift"
    39 = "ripgrep"
    40 = "cores"
    41 = "deleteSource"
    42 = "strip"
    43 = "pack"
    44 = "logging"
    45 = "updateSuite"
}
#>
$writeProperties = $false

if (Test-Path -Path $json) {
    $jsonProperties = Get-Content $json | ConvertFrom-Json
    foreach ($a in ($jsonObjects.psobject.Properties.Name)) {
        if ($jsonProperties.$a -ne 0) {
            $jsonObjects.$a = $jsonProperties.$a
        }
        else {
            $writeProperties = $true
        }
    }
}
else {
    $jsonObjects | ConvertTo-Json | Out-File $json
    $writeProperties = $true
}

# sytemVars
foreach ($a in ($order.psobject.Properties.Name)) {
    #$a = $order.$b
    if ($a -eq "msys2Arch") {
        $msys2 = switch ($jsonObjects.msys2Arch) {
            1 {
                "msys32"
            }
            2 {
                "msys64"
            }
        }
    }
    elseif ($jsonObjects.$a -eq 0) {
        while (1..$(
                switch ($a) {
                    arch {3}
                    license2 {5}
                    x2643 {7}
                    x2652 {7}
                    ffmpegB2 {5}
                    ffmpegUpdate {3}
                    ffmpegChoice {4}
                    mpv {3}
                    curl {7}
                    cores {999}
                    Default {2}
                }
            ) -notcontains $jsonObjects.$a) {
            Write-host "-------------------------------------------------------------------------------"
            Write-host "-------------------------------------------------------------------------------`n"
            switch ($a) {
                arch {
                    Write-Host "Select the build target system:"
                }
                license2 {
                    Write-Host "Build FFmpeg with which license?"
                    Write-Host "If building for yourself, it's OK to choose non-free."
                    Write-Host "If building to redistribute online, choose GPL or LGPL."
                    Write-Host "If building to include in a GPLv2.1 binary, choose LGPLv2.1 or GPLv2.1."
                    Write-Host "If you want to use FFmpeg together with closed source software, choose LGPL"
                    Write-Host "and follow instructions in https://www.ffmpeg.org/legal.html`n"
                    Write-Host "OpenSSL and FDK-AAC have licenses incompatible with GPL but compatible"
                    Write-Host "with LGPL, so they won't be disabled automatically if you choose LGPL.`n"
                }
                standalone {
                    Write-host "Build standalone binaries for libraries included in FFmpeg?"
                    Write-host "eg. Compile opusenc.exe if --enable-libopus`n"
                }
                vpx2 {
                    Write-Host "Build vpx [VP8/VP9/VP10 encoder]?"
                    Write-host "Binaries being built depends on 'standalone=y'`n"
                }
                aom {
                    Write-Host "Build aom [Alliance for Open Media codec]?"
                    Write-host "Binaries being built depends on 'standalone=y'`n"
                }
                rav1e {
                    Write-host "Build rav1e [Alternative, faster AV1 standalone encoder]?`n"
                }
                dav1d {
                    Write-Host "Build dav1d [Alternative, faster AV1 decoder]?`n"
                }
                x2643 {
                    Write-host "Build x264 [H.264 encoder]?"
                    Write-host "Binaries being built depends on 'standalone=y' and are always static.`n"
                }
                x2652 {
                    Write-host "Build x265 [H.265 encoder]?"
                    Write-host "Binaries being built depends on 'standalone=y'`n"
                }
                other265 {
                    Write-Host "Build standalone Kvazaar [H.265 encoder]?`n"
                }
                vvc {
                    Write-Host "Build Fraunhofer VVC [H.265 successor enc/decoder]?`n"
                }
                flac {
                    Write-Host "Build FLAC [Free Lossless Audio Codec]?`n"
                }
                fdkaac {
                    Write-Host "Build FDK-AAC library and binary [AAC-LC/HE/HEv2 codec]?"
                    Write-host "Note: FFmpeg's aac encoder is no longer experimental and considered equal or"
                    Write-host "better in quality from 96kbps and above. It still doesn't support AAC-HE/HEv2"
                    Write-host "so if you need that or want better quality at lower bitrates than 96kbps,"
                    Write-host "use FDK-AAC.`n"
                }
                faac {
                    Write-Host "Build FAAC library and binary [old, low-quality and nonfree AAC-LC codec]?`n"
                }
                mediainfo {
                    Write-Host "Build mediainfo binaries [Multimedia file information tool]?`n"
                }
                soxB {
                    Write-Host "Build sox binaries [Sound processing tool]?`n"
                }
                ffmpegB2 {
                    Write-host "Build FFmpeg binaries and libraries:"
                    Write-host "Note: Option 5 differs from 3 in that libass, freetype and fribidi are"
                    Write-host "compiled shared so they take less space. This one isn't tested a lot and"
                    Write-host "will fail with fontconfig enabled.`n"
                }
                ffmpegUpdate {
                    Write-host "Always build FFmpeg when libraries have been updated?"
                    Write-host "FFmpeg is updated a lot so you only need to select this if you"
                    Write-host "absolutely need updated external libraries in FFmpeg.`n"
                }
                ffmpegChoice {
                    Write-host "Choose ffmpeg and mpv optional libraries?"
                    Write-host "Avoid the last two unless you're really want useless libraries you'll never use."
                    Write-host "Just because you can include a shitty codec no one uses doesn't mean you should.`n"
                    Write-host "If you select yes, we will create files with the default options"
                    Write-host "we use with FFmpeg and mpv. You can remove any that you don't need or prefix"
                    Write-host "them with #`n"
                }
                mp4box {
                    Write-Host "Build static mp4box [mp4 muxer/toolbox] binary?`n"
                }
                rtmpdump {
                    Write-Host "Build static rtmpdump binaries [rtmp tools]?`n"
                }
                mplayer2 {
                    Write-Host "######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################`n"
                    Write-host "Build static mplayer/mencoder binary?"
                    Write-host "Don't bother opening issues about this if it breaks, I don't fucking care"
                    Write-host "about ancient unmaintained shit code. One more issue open about this that"
                    Write-host "isn't the suite's fault and mplayer goes fucking out.`n"
                }
                mpv {
                    Write-host "Build mpv?"
                    Write-host "Note: when built with shared-only FFmpeg, mpv is also shared."
                    Write-host "Note: Requires at least Windows Vista."
                    Write-host "Warning: the third option isn't completely static. There's no way to include"
                    Write-host "a library dependant on Python statically. All users of the compiled binary"
                    Write-host "will need VapourSynth installed using the official package to even open mpv!`n"
                }
                bmx {
                    Write-Host "Build static bmx tools?`n"
                }
                curl {
                    Write-host "Build static curl?"
                    Write-host "A curl-ca-bundle.crt will be created to be used as trusted certificate store"
                    Write-host "for all backends except SChannel.`n"
                }
                ffmbc {
                    Write-Host "######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################`n"
                    Write-host "Build FFMedia Broadcast binary?"
                    Write-host "Note: this is a fork of FFmpeg 0.10. As such, it's very likely to fail"
                    Write-host "to build, work, might burn your computer, kill your children, like mplayer."
                    Write-host "Only enable it if you absolutely need it. If it breaks, complain first to"
                    Write-host "the author in #ffmbc in Freenode IRC.`n"
                }
                cyanrip2 {
                    Write-Host "Build cyanrip (CLI CD ripper)?`n"
                }
                redshift {
                    Write-Host "Build redshift [f.lux FOSS clone]?`n"
                }
                ripgrep {
                    Write-Host "Build ripgrep [faster grep in Rust]?`n"
                }
                cores {
                    Write-Host "Number of CPU Cores/Threads for compiling:"
                    Write-Host "[it is non-recommended to use all cores/threads!]`n"
                }
                deleteSource {
                    Write-Host "Delete versioned source folders after compile is done?"
                    Write-Host "This will save a bit of space for libraries not compiled from git/hg/svn.`n"
                }
                strip {
                    Write-Host "Strip compiled files binaries?"
                    Write-Host "Makes binaries smaller at only a small time cost after compiling.`n"
                }
                pack {
                    Write-Host "Pack compiled files?"
                    Write-Host "Attention: Some security applications may detect packed binaries as malware."
                    Write-Host "Increases delay on runtime during which files need to be unpacked."
                    Write-Host "Makes binaries smaller at a big time cost after compiling and on runtime."
                    Write-Host "If distributing the files, consider packing them with 7-zip instead.`n"
                }
                logging {
                    Write-Host "Write logs of compilation commands?"
                    Write-Host "Note: Setting this to yes will also hide output from these commands."
                    Write-Host "On successful compilation, these logs are deleted since they aren't needed.`n"
                }
                updateSuite {
                    Write-Host "Create script to update suite files automatically?"
                    Write-Host "If you have made changes to the scripts, they will be reset but saved to"
                    Write-Host "a .diff text file inside $build`n"
                }
                Default {
                }
            }
            switch ($a) {
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
                    Write-host "5 = Shared-only with some shared libs ^(libass, freetype and fribidi^)`n"
                }
                ffmpegUpdate {
                    Write-host "1 = Yes"
                    Write-host "2 = No"
                    Write-host "3 = Only build FFmpeg/mpv and missing dependencies`n"
                }
                ffmpegChoice {
                    Write-host "1 = Yes"
                    Write-host "2 = No ^(Light build^)"
                    Write-host "3 = No ^(Mimic Zeranoe^)"
                    Write-host "4 = No ^(All available external libs^)`n"
                }
                mpv {
                    Write-host "1 = Yes"
                    Write-host "2 = No"
                    Write-host "3 = compile with Vapoursynth, if installed [see Warning]`n"
                }
                curl {
                    Write-host "1 = Yes [same backend as FFmpeg's]"
                    Write-host "2 = No"
                    Write-host "3 = SChannel backend"
                    Write-host "4 = GnuTLS backend"
                    Write-host "5 = OpenSSL backend"
                    Write-host "6 = LibreSSL backend"
                    Write-host "7 = mbedTLS backend`n"
                }
                cores {
                    Write-Host "Recommended: $(switch ((Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors) {
                        1 {1}
                        Default {(Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors / 2}
                    })`n"
                }
                deleteSource {
                    Write-host "1 = Yes [recommended]"
                    Write-host "2 = No`n"
                }
                strip {
                    Write-host "1 = Yes [recommended]"
                    Write-host "2 = No`n"
                }
                pack {
                    Write-host "1 = Yes"
                    Write-host "2 = No [recommended]`n"
                }
                logging {
                    Write-host "1 = Yes [recommended]"
                    Write-host "2 = No`n"
                }
                Default {
                    Write-host "1 = Yes"
                    Write-host "2 = No`n"
                }
            }
            Write-host "-------------------------------------------------------------------------------"
            Write-host "-------------------------------------------------------------------------------"
            $jsonObjects.$a = [int](
                Read-Host -Prompt $(
                    switch ($a) {
                        arch {
                            "Build System: "
                        }
                        license2 {
                            "FFmpeg license: "
                        }
                        standalone {
                            "Build standalone binaries: "
                        }
                        vpx2 {
                            "Build vpx: "
                        }
                        x2643 {
                            "Build x264: "
                        }
                        x2652 {
                            "Build x265: "
                        }
                        other265 {
                            "Build kvazaar: "
                        }
                        soxB {
                            "Build sox: "
                        }
                        ffmpegB2 {
                            "Build FFmpeg: "
                        }
                        ffmpegUpdate {
                            "Build ffmpeg if lib is new: "
                        }
                        ffmpegChoice {
                            "Choose ffmpeg and mpv optional libs: "
                        }
                        mplayer2 {
                            "Build mplayer: "
                        }
                        cyanrip2 {
                            "Build cyanrip: "
                        }
                        cores {
                            "Core/Thread Count: "
                        }
                        deleteSource {
                            "Delete source: "
                        }
                        strip {
                            "Strip files: "
                        }
                        pack {
                            "Pack files: "
                        }
                        logging {
                            "Write logs: "
                        }
                        updateSuite {
                            "Create update script: "
                        }
                        Default {
                            "Build $($a): "
                        }
                    }
                )
            )
        }
        if ($writeProperties) {
            ConvertTo-Json -InputObject $jsonObjects | Out-File $json
        }
    }
    else {
        switch ($a) {
            arch {
                $build32 = switch ($jsonObjects.arch) {
                    1 {
                        "yes"
                    }
                    2 {
                        "yes"
                    }
                    Default {
                        "no"
                    }
                }
                $build64 = switch ($jsonObjects.arch) {
                    1 {
                        "yes"
                    }
                    3 {
                        "yes"
                    }
                    Default {
                        "no"
                    }
                }
            }
            license2 {
                $license2 = switch ($jsonObjects.license2) {
                    1 {
                        "nonfree"
                    }
                    2 {
                        "gplv3"
                    }
                    3 {
                        "gpl"
                    }
                    4 {
                        "lgplv3"
                    }
                    5 {
                        "lgpl"
                    }
                }
            }
            x2643 {
                $x2643 = switch ($jsonObjects.x2643) {
                    1 {
                        "yes"
                    }
                    2 {
                        "no"
                    }
                    3 {
                        "high"
                    }
                    4 {
                        "full"
                    }
                    5 {
                        "shared"
                    }
                    6 {
                        "fullv"
                    }
                    7 {
                        "o8"
                    }
                }
            }
            x2652 {
                $x2652 = switch ($jsonObjects.x2652) {
                    1 {
                        "y"
                    }
                    2 {
                        "n"
                    }
                    3 {
                        "o10"
                    }
                    4 {
                        "o8"
                    }
                    5 {
                        "s"
                    }
                    6 {
                        "d"
                    }
                    7 {
                        "o12"
                    }
                }
            }
            ffmpegB2 {
                $ffmpeg = switch ($jsonObjects.ffmpegB2) {
                    1 {
                        "static"
                    }
                    2 {
                        "no"
                    }
                    3 {
                        "shared"
                    }
                    4 {
                        "both"
                    }
                    5 {
                        "sharedlibs"
                    }
                }
            }
            ffmpegUpdate {
                $ffmpegUpdate = switch ($jsonObjects.ffmpegUpdate) {
                    1 {
                        "y"
                    }
                    2 {
                        "n"
                    }
                    3 {
                        "onlyFFmpeg"
                    }
                }
            }
            ffmpegChoice {
                function Write-Option {
                    param (
                        [array]$inp
                    )
                    foreach ($opt in $inp) {
                        if (($opt | Out-String).StartsWith("--")) {
                            Write-Output $opt
                        }
                        elseif (($opt | Out-String).StartsWith("#--")) {
                            Write-Output $opt
                        }
                        elseif (($opt | Out-String).StartsWith("#")) {
                            $opta = ($opt | Out-String -NoNewline).Substring(1)
                            Write-Output "#--enable-$opta"
                        }
                        else {
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
                            Write-Host "-------------------------------------------------------------------------------"
                            Write-Host "File with default FFmpeg options has been created in $ffmpegoptions`n"
                            Write-Host "Edit it now or leave it unedited to compile according to defaults."
                            Write-Host "-------------------------------------------------------------------------------"
                            Pause
                        }
                        if (!(Test-Path -PathType Leaf $mpvoptions)) {
                            Write-Output "# Lines starting with this character are ignored`n`n# Built-in options, use --disable- to disable them." | Out-File $mpvoptions
                            Write-Option $mpv_options_builtin | Out-File -Append $mpvoptions
                            Write-Output "`n# Common options or overriden defaults" | Out-File -Append $mpvoptions
                            Write-Option $mpv_options_basic | Out-File -Append $mpvoptions
                            Write-Output "`n# Full" | Out-File -Append $mpvoptions
                            Write-Option $mpv_options_full | Out-File -Append $mpvoptions
                            Write-Host "-------------------------------------------------------------------------------"
                            Write-Host "File with default mpv options has been created in $mpvoptions`n"
                            Write-Host "Edit it now or leave it unedited to compile according to defaults."
                            Write-Host "-------------------------------------------------------------------------------"
                            Pause
                        }

                    }
                    2 {
                        $ffmpegChoice = "n"
                    }
                    3 {
                        $ffmpegChoice = "z"
                    }
                    4 {
                        $ffmpegChoice = "f"
                    }
                }
            }
            mpv {
                $mpv = switch ($jsonObjects.mpv) {
                    1 {
                        "y"
                    }
                    2 {
                        "n"
                    }
                    3 {
                        "z"
                    }
                }
            }
            curl {
                $curl = switch ($jsonObjects.curl) {
                    1 {
                        "y"
                    }
                    2 {
                        "n"
                    }
                    3 {
                        "schannel"
                    }
                    4 {
                        "gnutls"
                    }
                    5 {
                        "openssl"
                    }
                    6 {
                        "libressl"
                    }
                    7 {
                        "mbedtls"
                    }
                }
            }
            cyanrip2 {
                $cyanrip2 = switch ($jsonObjects.cyanrip2) {
                    1 {
                        "yes"
                    }
                    2 {
                        "no"
                    }
                }
            }
            Default {
                Set-Variable -Name $($a) -Value $(
                    switch ($jsonObjects.$a) {
                        1 {
                            "y"
                        }
                        2 {
                            "n"
                        }
                    }
                )
            }
        }
    }
    switch ($a) {
        arch {
            $build32 = switch ($jsonObjects.arch) {
                1 {
                    "yes"
                }
                2 {
                    "yes"
                }
                Default {
                    "no"
                }
            }
            $build64 = switch ($jsonObjects.arch) {
                1 {
                    "yes"
                }
                3 {
                    "yes"
                }
                Default {
                    "no"
                }
            }
        }
        license2 {
            $license2 = switch ($jsonObjects.license2) {
                1 {
                    "nonfree"
                }
                2 {
                    "gplv3"
                }
                3 {
                    "gpl"
                }
                4 {
                    "lgplv3"
                }
                5 {
                    "lgpl"
                }
            }
        }
        x2643 {
            $x2643 = switch ($jsonObjects.x2643) {
                1 {
                    "yes"
                }
                2 {
                    "no"
                }
                3 {
                    "high"
                }
                4 {
                    "full"
                }
                5 {
                    "shared"
                }
                6 {
                    "fullv"
                }
                7 {
                    "o8"
                }
            }
        }
        x2652 {
            $x2652 = switch ($jsonObjects.x2652) {
                1 {
                    "y"
                }
                2 {
                    "n"
                }
                3 {
                    "o10"
                }
                4 {
                    "o8"
                }
                5 {
                    "s"
                }
                6 {
                    "d"
                }
                7 {
                    "o12"
                }
            }
        }
        ffmpegB2 {
            $ffmpeg = switch ($jsonObjects.ffmpegB2) {
                1 {
                    "static"
                }
                2 {
                    "no"
                }
                3 {
                    "shared"
                }
                4 {
                    "both"
                }
                5 {
                    "sharedlibs"
                }
            }
        }
        ffmpegUpdate {
            $ffmpegUpdate = switch ($jsonObjects.ffmpegUpdate) {
                1 {
                    "y"
                }
                2 {
                    "n"
                }
                3 {
                    "onlyFFmpeg"
                }
            }
        }
        ffmpegChoice {
            # writeOption
            function Write-Option {
                param (
                    [array]$inp
                )
                foreach ($opt in $inp) {
                    if (($opt | Out-String).StartsWith("--")) {
                        Write-Output $opt
                    }
                    elseif (($opt | Out-String).StartsWith("#--")) {
                        Write-Output $opt
                    }
                    elseif (($opt | Out-String).StartsWith("#")) {
                        $opta = ($opt | Out-String -NoNewline).Substring(1)
                        Write-Output "#--enable-$opta"
                    }
                    else {
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
                        Write-Host "-------------------------------------------------------------------------------"
                        Write-Host "File with default FFmpeg options has been created in $ffmpegoptions`n"
                        Write-Host "Edit it now or leave it unedited to compile according to defaults."
                        Write-Host "-------------------------------------------------------------------------------"
                        Pause
                    }
                    if (!(Test-Path -PathType Leaf $mpvoptions)) {
                        Write-Output "# Lines starting with this character are ignored`n`n# Built-in options, use --disable- to disable them." | Out-File $mpvoptions
                        Write-Option $mpv_options_builtin | Out-File -Append $mpvoptions
                        Write-Output "`n# Common options or overriden defaults" | Out-File -Append $mpvoptions
                        Write-Option $mpv_options_basic | Out-File -Append $mpvoptions
                        Write-Output "`n# Full" | Out-File -Append $mpvoptions
                        Write-Option $mpv_options_full | Out-File -Append $mpvoptions
                        Write-Host "-------------------------------------------------------------------------------"
                        Write-Host "File with default mpv options has been created in $mpvoptions`n"
                        Write-Host "Edit it now or leave it unedited to compile according to defaults."
                        Write-Host "-------------------------------------------------------------------------------"
                        Pause
                    }

                }
                2 {
                    $ffmpegChoice = "n"
                }
                3 {
                    $ffmpegChoice = "z"
                }
                4 {
                    $ffmpegChoice = "f"
                }
            }
        }
        mpv {
            $mpv = switch ($jsonObjects.mpv) {
                1 {
                    "y"
                }
                2 {
                    "n"
                }
                3 {
                    "z"
                }
            }
        }
        curl {
            $curl = switch ($jsonObjects.curl) {
                1 {
                    "y"
                }
                2 {
                    "n"
                }
                3 {
                    "schannel"
                }
                4 {
                    "gnutls"
                }
                5 {
                    "openssl"
                }
                6 {
                    "libressl"
                }
                7 {
                    "mbedtls"
                }
            }
        }
        cyanrip2 {
            $cyanrip2 = switch ($jsonObjects.cyanrip2) {
                1 {
                    "yes"
                }
                2 {
                    "no"
                }
            }
        }
        Default {
            Set-Variable -Name $($a) -Value $(
                switch ($jsonObjects.$a) {
                    1 {
                        "y"
                    }
                    2 {
                        "n"
                    }
                }
            )
        }
    }
}
# EOQuestions

Write-Host "-------------------------------------------------------------"
Write-Host "If you want to reuse this console (ran powershell then ran this script instead of clicking this script) do"
Write-Host "`$env:Path = `$Global:TempPath"
Write-Host "else you won't have your original path in this console until you close and reopen."
Write-Host "If you use control+C at any time durring the script, make sure to run"
Write-Host "Get-Job | Remove-Job -Force"
Write-Host "-------------------------------------------------------------"
Start-Sleep -Seconds 2
# Temporarily store the Path
if (!(Test-Path variable:global:TempPath)) {$Global:TempPath = $env:Path}
$env:Path = $($Global:TempPath.Split(';') -match "NVIDIA|Windows" -join ';') + ";$PSScriptRoot\msys64\usr\bin"
$msys2Path = "$PSScriptRoot\$msys2"
$bash = "$msys2Path\usr\bin\bash.exe"
$msysprefix = switch ($msys2) {
    msys32 {
        "i686"
    }
    Default {
        "x86_64"
    }
}
if (!(Test-Path $msys2Path\usr\bin\wget.exe)) {
    Write-Host "-------------------------------------------------------------`n"
    Write-Host "- Downloading Wget`n"
    Write-Host "-------------------------------------------------------------"
    Set-Location $build
    if ((!(Test-Path $build\7za.exe)) -or (!(Test-Path $build\grep.exe))) {
        while (!(Test-Path $build\wget.exe)) {
            $progressPreference = 'silentlyContinue'
            if ($(Test-Connection -Quiet -ComputerName i.fsbn.eu -Count 1 -InformationAction Ignore)) {
                Invoke-WebRequest -Resume -OutFile "$build\wget-pack.exe" -Uri "https://i.fsbn.eu/pub/wget-pack.exe"
            }
            elseif ($(Test-Connection -Quiet -ComputerName randomderp.com -Count 1 -InformationAction Ignore)) {
                Invoke-WebRequest -Resume -OutFile "$build\wget-pack.exe" -Uri "https://randomderp.com/wget-pack.exe"
            }
            else {
                Write-Host "-------------------------------------------------------------`n"
                Write-Host "Script to download necessary components failed.`n"
                Write-Host "Download and extract this manually to inside $($build):"
                Write-Host "https://i.fsbn.eu/pub/wget-pack.exe`n"
                Write-Host "-------------------------------------------------------------"
                Pause
                exit
            }
            $progressPreference = 'Continue'
            if ((Get-FileHash -Algorithm SHA256 -Path "$build\wget-pack.exe").hash -eq "3F226318A73987227674A4FEDDE47DF07E85A48744A07C7F6CDD4F908EF28947") {
                Start-Process -NoNewWindow -Wait -FilePath $build\wget-pack.exe  -WorkingDirectory $build
            }
            else {
                Remove-Item $build\wget-pack.exe
                Write-Host "-------------------------------------------------------------`n"
                Write-Host "Script to download necessary components failed.`n"
                Write-Host "Download and extract this manually to inside $($build):"
                Write-Host "https://i.fsbn.eu/pub/wget-pack.exe`n"
                Write-Host "-------------------------------------------------------------"
                Pause
                exit
            }
        }
        Remove-Item $build\wget-pack.exe
    }
}


if (!(Test-Path $msys2Path\msys2_shell.cmd)) {
    Write-Host "-------------------------------------------------------------`n"
    Write-Host "- Download and install msys2 basic system`n"
    Write-Host "-------------------------------------------------------------"
    Invoke-WebRequest -Resume -MaximumRetryCount 5 -RetryIntervalSec 5 -OutFile $build\msys2-base.tar.xz -Uri "http://repo.msys2.org/distrib/msys2-$($msysprefix)-latest.tar.xz"
    if (Test-Path $build\msys2-base.tar.xz) {
        Start-Process -WorkingDirectory $build -Wait -NoNewWindow -FilePath $build\7za.exe -ArgumentList "x -aoa msys2-base.tar.xz"
        Remove-Item $build\msys2-base.tar.xz
        Start-Process -WorkingDirectory $build -Wait -NoNewWindow -FilePath $build\7za.exe -ArgumentList "x -aoa msys2-base.tar -o.."
        Remove-Item $build\msys2-base.tar

    }
    if (!(Test-Path $PSScriptRoot\$msys2\usr\bin\msys-2.0.dll)) {
        Write-Host "-------------------------------------------------------------`n"
        Write-Host "- Download msys2 basic system failed,"
        Write-Host "- please download it manually from:"
        Write-Host "- http://repo.msys2.org/distrib/"
        Write-Host "- and copy the uncompressed folder to:"
        Write-Host "- $build"
        Write-Host "- and start the batch script again!`n"
        Write-Host "-------------------------------------------------------------"
        pause
        exit
    }
}

# createFolders
function Write-BaseFolders ([int]$bit) {
    if (!(Test-Path $PSScriptRoot\local$bit\share -PathType Container)) {
        Write-Host "-------------------------------------------------------------"
        Write-Host "creating $bit-bit install folders"
        Write-Host "-------------------------------------------------------------"
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-audio | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-global | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\bin-video | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\etc | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\include | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\lib\pkgconfig | Out-Null
        New-Item -ItemType Directory $PSScriptRoot\local$bit\share | Out-Null
    }
}
if ($build64 -eq "yes") {
    Write-BaseFolders -bit 64
}
if ($build32 -eq "yes") {
    Write-BaseFolders -bit 32
}
$fstab = "$msys2Path\etc\fstab"
# checkFstab
function Write-Fstab {
    Write-Host "-------------------------------------------------------------`n"
    Write-Host "- write fstab mount file`n"
    Write-Host "-------------------------------------------------------------"
    $(
        Write-Output "none / cygdrive binary,posix=0,noacl,user 0 0`n"
        Write-Output "$PSScriptRoot\ /trunk`n"
        Write-Output "$PSScriptRoot\build\ /build`n"
        Write-Output "$msys2Path\mingw32\ /mingw32`n"
        Write-Output "$msys2Path\mingw64\ /mingw64`n"
    ) | Out-File -NoNewline -Force $fstab
    if ($build32 -eq "yes") {
        Write-Output "$PSScriptRoot\local32\ /local32" | Out-File -NoNewline -Append $fstab
    }
    if ($build64 -eq "yes") {
        Write-Output "$PSScriptRoot\local64\ /local64" | Out-File -NoNewline -Append $fstab
    }
}

if (!(Test-Path $PSScriptRoot\mintty.lnk)) {
    Set-Location $msys2Path
    if ($msys2 -eq "msys32") {
        Write-Host "-------------------------------------------------------------`n"
        Write-Host "rebase $msys2 system`n"
        Write-Host "-------------------------------------------------------------"
        Start-Process -Wait -NoNewWindow -FilePath $msys2Path\autorebase.bat
    }
    Start-Job -Name "firstRun" -ArgumentList $bash, $build -ScriptBlock {
        param($bash, $build)
        Write-Host "-------------------------------------------------------------"
        Write-Host "- make a first run"
        Write-Host "-------------------------------------------------------------"
        Remove-Item -Force $build\firstrun.log 2>&1 | Out-Null
        Invoke-Expression "$bash -lc exit" | Tee-Object $build\firstrun.log
    } | Receive-Job -Wait
    Write-Fstab
    Start-Job -Name "firstUpdate" -ArgumentList $bash, $build -ScriptBlock {
        param($bash, $build)
        Write-Host "-------------------------------------------------------------"
        Write-Host "First update"
        Write-Host "-------------------------------------------------------------"
        Remove-Item -Force $build\firstUpdate.log 2>&1 | Out-Null
        Invoke-Expression "$bash -lc 'echo First msys2 update; pacman -Sy --needed --ask=20 --noconfirm --asdeps pacman-mirrors ca-certificates'" | Tee-Object $build\firstUpdate.log
    } | Receive-Job -Wait
    Start-Job -Name "criticalUpdates" -ArgumentList $bash, $build -ScriptBlock {
        param($bash, $build)
        Write-Host "-------------------------------------------------------------"
        Write-Host "critical updates"
        Write-Host "-------------------------------------------------------------"
        Remove-Item -Force $build\criticalUpdate.log 2>&1 | Out-Null
        Invoke-Expression "$bash -lc 'pacman -Syyu --needed --ask=20 --noconfirm --asdeps'" | Tee-Object $build\criticalUpdate.log
    } | Receive-Job -Wait
    Start-Job -Name "secondUpdate" -ArgumentList $bash, $build -ScriptBlock {
        param($bash, $build)
        Write-Host "-------------------------------------------------------------"
        Write-Host "second update"
        Write-Host "-------------------------------------------------------------"
        Remove-Item -Force $build\secondUpdate.log 2>&1 | Out-Null
        Invoke-Expression "$bash -lc 'echo second msys2 update; pacman -Syyu --needed --ask=20 --noconfirm --asdeps'" | Tee-Object $build\secondUpdate.log
    } | Receive-Job -Wait
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
if ((($build32 -eq "yes") -and !(Select-String -Pattern "local32" -Path $fstab)) -or (($build64 -eq "yes") -and !(Select-String -Pattern "local64" -Path $fstab)) -or (($build32 -eq "no") -and (Select-String -Pattern "local32" -Path $fstab)) -or (($build64 -eq "no") -and (Select-String -Pattern "local64" -Path $fstab)) -or !(Select-String -Path $fstab -Pattern "trunk") -or (((Select-String -Path $fstab -Pattern "trunk").Line.Split(' ')[0] -ne $PSScriptRoot) -or (Select-String -Path $fstab -Pattern "build32") -or !(Test-Path $msys2Path\etc\fstab))) {
    Write-Fstab
}

if (!(Invoke-Expression "$bash -lc 'pacman-key -f EFD16019AE4FF531'")) {
    Start-Job -Name "forceSign" -ArgumentList $bash -ScriptBlock {
        param($bash)
        Write-Host "-------------------------------------------------------------"
        Write-Host "forcefully signing key"
        Write-Host "-------------------------------------------------------------"
        Invoke-Expression "$bash -lc 'echo Forcefully signing abrepo key; pacman-key -r EFD16019AE4FF531; pacman-key --lsign EFD16019AE4FF531'"
    } | Receive-Job -Wait
}

New-Item -ItemType Directory -Force -Path $msys2Path\home\$env:UserName | Out-Null
if (!(Test-Path "$msys2Path\home\$env:UserName\.minttyrc")) {
    Write-Output "Locale=en_US`nCharset=UTF-8`nFont=Consolas`nColumns=120`nRows=30" | Out-File -NoNewline -Force $msys2Path\home\$env:UserName\.minttyrc
}

if (!(Test-Path "$msys2Path\home\$env:UserName\.hgrc")) {
    $(
        Write-Output "[ui]`n"
        Write-Output "username = $env:UserName`n"
        Write-Output "verbose = True`n"
        Write-Output "editor = vim`n`n"
        Write-Output "[web]`n"
        Write-Output "cacerts=/usr/ssl/cert.pem`n`n"
        Write-Output "[extensions]`n"
        Write-Output "color =`n`n"
        Write-Output "[color]`n"
        Write-Output "status.modified = magenta bold`n"
        Write-Output "status.added = green bold`n"
        Write-Output "status.removed = red bold`n"
        Write-Output "status.deleted = cyan bold`n"
        Write-Output "status.unknown = blue bold`n"
        Write-Output "status.ignored = black bold`n"
    ) | Out-File -NoNewline -Force $msys2Path\home\$env:UserName\.hgrc
}

if (!(Test-Path $msys2Path\home\$env:UserName\.gitconfig -ErrorAction Ignore)) {
    $(
        Write-Output "[user]`n"
        Write-Output "name = $env:UserName`n"
        Write-Output "email = $env:UserName@$env:COMPUTERNAME`n`n"
        Write-Output "[color]`n"
        Write-Output "ui = true`n`n"
        Write-Output "[core]`n"
        Write-Output "editor = vim"`n
        Write-Output "autocrlf =`n`n"
        Write-Output "[merge]`n"
        Write-Output "tool = vimdiff`n`n"
        Write-Output "[push]`n"
        Write-Output "default = simple`n"
    ) | Out-File -NoNewline -Force $msys2Path\home\$env:UserName\.gitconfig
}

Remove-Item $msys2Path\etc\pac-base.pk -Force 2>&1 | Out-Null
foreach ($i in $msyspackages) {
    Write-Output "$i" | Out-File -Append $msys2Path\etc\pac-base.pk
}
Remove-Item $msys2Path\etc\pac-base.temp -Force 2>&1 | Out-Null
foreach ($i in $msyspackages) {
    Write-Output "$i`n" | Out-File -Append -NoNewline $msys2Path\etc\pac-base.temp
}

if (!(Test-Path $msys2Path\usr\bin\make.exe)) {
    Start-Job -Name "installMsys2" -ArgumentList $bash, $build -ScriptBlock {
        param($bash, $build)
        Write-Host "-------------------------------------------------------------"
        Write-Host "install msys2 base system"
        Write-Host "-------------------------------------------------------------"
        Remove-Item -Force $build\install_base_failed -ErrorAction Ignore
        Remove-Item -Force $build\pacman.log 2>&1 | Out-Null
        Invoke-Expression "$bash -lc 'echo install base system;  cat /etc/pac-base.temp | pacman -S --noconfirm --ask=20 --needed - ; cat /etc/pac-base.temp | pacman -D --asexplicit --noconfirm --ask=20 -'" | Tee-Object $build\pacman.log
    } | Receive-Job -Wait
}

Start-Job -Name "cert" -ArgumentList $bash, $build -ScriptBlock {
    param($bash, $build)
    Remove-Item -Force $build\cert.log 2>&1 | Out-Null
    Invoke-Expression "$bash -lc update-ca-trust" | Tee-Object $build\cert.log
} | Receive-Job -Wait

if (!(Test-Path "$msys2Path\usr\bin\hg.bat")) {
    Write-Output "`@echo off`r`n`r`nsetlocal`r`nset HG=%~f0`r`n`r`nset PYTHONHOME=`r`nset in=%*`r`nset out=%in: {= `"{%`r`nset out=%out:} =}`" %`r`n`r`n%~dp0python2 %~dp0hg %out%`r`n" | Out-File -Force -NoNewline $msys2Path\usr\bin\hg.bat
}

Remove-Item -Force $msys2Path\etc\pac-mingw.pk 2>&1 | Out-Null
foreach ($i in $mingwpackages) {
    Write-Output "$i" | Out-File -Append $msys2Path\etc\pac-mingw.pk
}

function Get-Compiler ([int]$bit) {
    Start-Job -Name "compiler" -ArgumentList $bash, $build, $bit, $msysprefix, $msys2Path -ScriptBlock {
        param(
            $bash,
            $build,
            [int]$bit,
            $msysprefix,
            $msys2Path
        )
        Write-Host "-------------------------------------------------------------"
        Write-Host "install $bit bit compiler"
        Write-Host "-------------------------------------------------------------"
        Remove-Item -Force $build\mingw$($bit).log 2>&1 | Out-Null
        Get-Content $msys2Path\etc\pac-mingw.pk | ForEach-Object {"mingw-w64-$($msysprefix)-" + $_ + "`n"} | Out-File -Force -NoNewline $msys2Path\etc\pac-mingw.temp
        Invoke-Expression "$bash -lc 'echo install $bit bit compiler; cat /etc/pac-mingw.temp | pacman -S --noconfirm --ask=20 --needed - ; cat /etc/pac-mingw.temp | pacman -D --asexplicit --noconfirm --ask=20 -'" | Tee-Object $build\mingw$($bit).log
        Remove-Item $msys2Path\etc\pac-mingw.temp
    } | Receive-Job -Wait
    if (!(Test-Path $msys2Path\mingw$($bit)\bin\gcc.exe)) {
        Write-Host "-------------------------------------------------------------"
        Write-Host "MinGW$($bit) GCC compiler isn't installed; maybe the download didn't work"
        Write-Host "Do you want to try it again?"
        Write-Host "-------------------------------------------------------------"
        if ($(Read-Host -Prompt "try again [y/n]: ") -eq "y") {
            Get-Compiler -bit $bit
        }
        else {
            exit
        }
    }
}
if (($build32 -eq "yes") -and !(Test-Path $msys2Path\mingw32\bin\gcc.exe)) {Get-Compiler -bit 32}
if (($build64 -eq "yes") -and !(Test-Path $msys2Path\mingw64\bin\gcc.exe)) {Get-Compiler -bit 64}

# updatebase
Write-Host "-------------------------------------------------------------"
Write-Host "update autobuild suite"
Write-Host "-------------------------------------------------------------"
$scripts = "compile", "helper", "update"
foreach ($s in $scripts) {
    if (!(Test-Path $build\media-suite_$($s).sh)) {
        Invoke-WebRequest -Resume -MaximumRetryCount 10 -RetryIntervalSec 2 -OutFile $build\media-suite_$($s).sh -Uri "https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/media-suite_$($s).sh"
    }
}
if ($jsonObjects.updateSuite -eq 1) {
    Write-Host "-------------------------------------------------------------"
    Write-Host "Creating suite update file...`n"
    Write-Host "Run this file by dragging it to mintty before the next time you run"
    Write-Host "the suite and before reporting an issue.`n"
    Write-Host "It needs to be run separately and with the suite not running!"
    Write-Host "-------------------------------------------------------------"
    $(
        Write-Output "#!/bin/bash`n`n# Run this file by dragging it to mintty shortcut.`n# Be sure the suite is not running before using it!`n`nupdate=yes`n"
        Get-Content $build\media-suite_update.sh | Select-Object -Index ($((Select-String -Path $build\media-suite_update.sh -Pattern "start suite update").LineNumber)..$((Select-String -Path $build\media-suite_update.sh -Pattern "end suite update").LineNumber)) | ForEach-Object {$_ + "`n"}
    ) | Out-File -NoNewline -Force $PSScriptRoot\update_suite.sh
}

# update
Remove-Item -Force $build\update.log 2>&1 | Out-Null
Start-Job -Name "ExplicitAndDeps" -ArgumentList $bash, $build -ScriptBlock {
    param($bash, $build)
    Invoke-Expression "$bash -lc 'pacman -D --asexplicit --noconfirm --ask=20 mintty; pacman -D --asdep --noconfirm --ask=20 bzip2 findutils flex getent gzip inetutils lndir msys2-keyring msys2-launcher-git pactoys-git pax-git tftp-hpa tzcode which'"
} | Receive-Job -Wait
Start-Job -Name "update" -ArgumentList $bash, $build, $build32, $build64 -ScriptBlock {
    param($bash, $build, $build32, $build64)
    Invoke-Expression "$bash -lc 'echo no | /build/media-suite_update.sh --build32=$build32 --build64=$build64'" | Tee-Object $build\update.log
} | Receive-Job -Wait
if (Test-Path $build\update_core) {
    Start-Job -Name "criticalUpdates" -ArgumentList $bash, $build -ScriptBlock {
        param($bash, $build)
        Write-Host "-------------------------------------------------------------"
        Write-Host "critical updates"
        Write-Host "-------------------------------------------------------------"
        Remove-Item -Force $build\update_core.log 2>&1 | Out-Null
        Invoke-Expression  "$bash -lc 'pacman -Syyu --needed --noconfirm --ask=20 --asdeps'"
    } | Receive-Job -Wait | Tee-Object $build\update_core.log
    Remove-Item $build\update_core
}

if ($msys -eq "msys32") {
    Write-Host "-------------------------------------------------------------"
    Write-Host "second rebase $msys2 system"
    Write-Host "-------------------------------------------------------------"
    Start-Process -NoNewWindow -Wait -FilePath $msys2Path\autorebase.bat
}
# Write config profiles
function Write-Profile {
    param (
        [int]$bit
    )
    $(
        Write-Output "MSYSTEM=MINGW$bit`n"
        Write-Output "source /etc/msystem`n`n"
        Write-Output "# package build directory`n"
        Write-Output "LOCALBUILDDIR=/build`n"
        Write-Output "# package installation prefix`n"
        Write-Output "LOCALDESTDIR=/local$bit`n"
        Write-Output "export LOCALBUILDDIR LOCALDESTDIR`n`n"
        Write-Output "bits='$($bit)bit'`n`n"
        Write-Output "alias dir='ls -la --color=auto'`n"
        Write-Output "alias ls='ls --color=auto'`n"
        Write-Output "export CC=gcc`n`n"
        Write-Output "CARCH=`"$msysprefix`"`n"
        Write-Output "CPATH=`"``cygpath -m `$LOCALDESTDIR/include``;``cygpath -m `$MINGW_PREFIX/include```"`n"
        Write-Output "LIBRARY_PATH=`"``cygpath -m `$LOCALDESTDIR/lib``;``cygpath -m `$MINGW_PREFIX/lib```"`n"
        Write-Output "export CPATH LIBRARY_PATH`n`n"
        Write-Output "MANPATH=`"`$`{LOCALDESTDIR`}/share/man:`$`{MINGW_PREFIX`}/share/man:/usr/share/man`"`n"
        Write-Output "INFOPATH=`"`$`{LOCALDESTDIR`}/share/info:`$`{MINGW_PREFIX`}/share/info:/usr/share/info`"`n`n"
        Write-Output "DXSDK_DIR=`"`$`{MINGW_PREFIX`}/`$`{MINGW_CHOST`}`"`n"
        Write-Output "ACLOCAL_PATH=`"`$`{LOCALDESTDIR`}/share/aclocal:`$`{MINGW_PREFIX`}/share/aclocal:/usr/share/aclocal`"`n"
        Write-Output "PKG_CONFIG=`"`$`{MINGW_PREFIX`}/bin/pkg-config --static`"`n"
        Write-Output "PKG_CONFIG_PATH=`"`$`{LOCALDESTDIR`}/lib/pkgconfig:`$`{MINGW_PREFIX`}/lib/pkgconfig`"`n"
        Write-Output "CPPFLAGS=`"-D_FORTIFY_SOURCE=2 -D__USE_MINGW_ANSI_STDIO=1`"`n"
        Write-Output "CFLAGS=`"-mthreads -mtune=generic -O2 -pipe`"`n"
        Write-Output "CXXFLAGS=`"`$`{CFLAGS`}`"`n"
        Write-Output "LDFLAGS=`"-pipe -static-libgcc -static-libstdc++`"`n"
        Write-Output "export DXSDK_DIR ACLOCAL_PATH PKG_CONFIG PKG_CONFIG_PATH CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MSYSTEM`n`n"
        Write-Output "export CARGO_HOME=`"/opt/cargo`" RUSTUP_HOME=`"/opt/cargo`"`n`n"
        Write-Output "export PYTHONPATH=`n`n"
        Write-Output "LANG=en_US.UTF-8`n"
        Write-Output "PATH=`"`$`{LOCALDESTDIR`}/bin:`$`{MINGW_PREFIX`}/bin:`$`{INFOPATH`}:`$`{MSYS2_PATH`}:`$`{ORIGINAL_PATH`}`"`n"
        Write-Output "PATH=`"`$`{LOCALDESTDIR`}/bin-audio:`$`{LOCALDESTDIR`}/bin-global:`$`{LOCALDESTDIR`}/bin-video:`$`{PATH`}`"`n"
        Write-Output "PATH=`"/opt/cargo/bin:/opt/bin:`$`{PATH`}`"`n"
        Write-Output "source '/etc/profile.d/perlbin.sh'`n"
        Write-Output "PS1='\[\033[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '`n"
        Write-Output "HOME=`"/home/`$`{USERNAME`}`"`n"
        Write-Output "GIT_GUI_LIB_DIR=``cygpath -w /usr/share/git-gui/lib```n"
        Write-Output "export LANG PATH PS1 HOME GIT_GUI_LIB_DIR`n"
        Write-Output "stty susp undef`n"
        Write-Output "cd /trunk`n"
        Write-Output "test -f `"`$LOCALDESTDIR/etc/custom_profile`" && source `"`$LOCALDESTDIR/etc/custom_profile`"`n"
    ) | Out-File -NoNewline -Force $PSScriptRoot\local$($bit)\etc\profile2.local
}
if ($build32 -eq "yes") {Write-Profile -bit 32}
if ($build64 -eq "yes") {Write-Profile -bit 64}

# loginProfile
if (Test-Path $msys2Path\etc\profile.pacnew) {Move-Item -Force $msys2Path\etc\profile.pacnew $msys2Path\etc\profile}
if (!(Select-String -Pattern "profile2.local" -Path $msys2Path\etc\profile)) {
    Write-Output "if [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW64 ]]; then`n   source /local64/etc/profile2.local`nelif [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW32 ]]; then`n   source /local32/etc/profile2.local`nfi" | Out-File -NoNewline -Force $msys2Path\etc\profile.d\Zab-suite.sh
}

# compileLocals
$MSYSTEM = switch ($build32) {
    yes {"MINGW32"}
    Default {"MINGW64"}
}
Set-Location $PSScriptRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
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
    Remove-Item -Force $build\compile.log 2>&1 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Invoke-Expression  "$msys2Path\usr\bin\env MSYSTEM=$MSYSTEM MSYS2_PATH_TYPE=inherit /usr/bin/bash --login /build/media-suite_compile.sh --cpuCount=$cores --build32=$build32 --build64=$build64 --deleteSource=$deleteSource --mp4box=$mp4box --vpx=$vpx2 --x264=$x2643 --x265=$x2652 --other265=$other265 --flac=$flac --fdkaac=$fdkaac --mediainfo=$mediainfo --sox=$soxB --ffmpeg=$ffmpeg --ffmpegUpdate=$ffmpegUpdate --ffmpegChoice=$ffmpegChoice --mplayer=$mplayer2 --mpv=$mpv --license=$license2  --stripping=$strip --packing=$pack --rtmpdump=$rtmpdump --logging=$logging --bmx=$bmx --standalone=$standalone --aom=$aom --faac=$faac --ffmbc=$ffmbc --curl=$curl --cyanrip=$cyanrip2 --redshift=$redshift --rav1e=$rav1e --ripgrep=$ripgrep --dav1d=$dav1d --vvc=$vvc" | Tee-Object $build\compile.log
}
while (Get-Job -State Running) {
    Receive-Job -Name "Media-Autobuild_Suite Compile" | Out-Host
}
$env:Path = $Global:TempPath