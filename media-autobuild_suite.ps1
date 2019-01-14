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
    Write-Output "Your Powershell version is too low!"
    Write-Output "Please update your version either through an OS upgrade"
    Write-Output "or download the latest version for your system from"
    Write-Output "https://github.com/PowerShell/PowerShell"
    Pause
    exit
}
#requires -Version 4
if ($PSScriptRoot -match " ") {
    Write-Output "$("-"*70)"
    Write-Output "You have probably run the script in a path with spaces.`n"
    Write-Output "This is not supported.`n"
    Write-Output "Please move the script to use a path without spaces. Example:`n"
    Write-Output "Incorrect: C:\build suite\`n"
    Write-Output "Correct:   C:\build_suite\`n"
    Pause
    exit
} elseif ($PSScriptRoot.Length -gt 60) {
    Write-Output "$("-"*70)"
    Write-Output "The total filepath to the suite seems too large (larger than 60 characters):`n"
    Write-Output "$PSScriptRoot`n"
    Write-Output "Some packages might fail building because of it.`n"
    Write-Output "Please move the suite directory closer to the root of your drive and maybe`n"
    Write-Output "rename the suite directory to a smaller name. Examples:`n"
    Write-Output "Avoid:  C:\Users\Administrator\Desktop\testing\media-autobuild_suite-master`n"
    Write-Output "Prefer: C:\media-autobuild_suite or `n"
    Write-Output "Prefer: C:\ab-suite`n"
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
    #copybin     = 0
    #installdir  = $null
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
        other265 {Write-Output "Build standalone Kvazaar [H.265 encoder]?"}
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
        arch {
            Write-Output "1 = both [32 bit and 64 bit]"
            Write-Output "2 = 32 bit build system"
            Write-Output "3 = 64 bit build system`n"
        }
        license2 {
            Write-Output "1 = Non-free [unredistributable, but can include anything]"
            Write-Output "2 = GPLv3 [disables OpenSSL and FDK-AAC]"
            Write-Output "3 = GPLv2.1 [Same disables as GPLv3 with addition of gmp, opencore codecs]"
            Write-Output "4 = LGPLv3 [Disables x264, x265, XviD, GPL filters, etc."
            Write-Output "   but reenables OpenSSL/FDK-AAC]"
            Write-Output "5 = LGPLv2.1 [same disables as LGPLv3 + GPLv2.1]`n"
            Write-Output "If building for yourself, it's OK to choose non-free."
            Write-Output "If building to redistribute online, choose GPL or LGPL."
            Write-Output "If building to include in a GPLv2.1 binary, choose LGPLv2.1 or GPLv2.1."
            Write-Output "If you want to use FFmpeg together with closed source software, choose LGPL"
            Write-Output "and follow instructions in https://www.ffmpeg.org/legal.html`n"
            Write-Output "OpenSSL and FDK-AAC have licenses incompatible with GPL but compatible"
            Write-Output "with LGPL, so they won't be disabled automatically if you choose LGPL.`n"
        }
        x2643 {
            Write-Output "1 = Lib/binary with 8 and 10-bit"
            Write-Output "2 = No"
            Write-Output "3 = Lib/binary with only 10-bit"
            Write-Output "4 = Lib/binary with 8 and 10-bit, and libavformat and ffms2"
            Write-Output "5 = Shared lib/binary with 8 and 10-bit"
            Write-Output "6 = Same as 4 with video codecs only ^(can reduce size by ~3MB^)"
            Write-Output "7 = Lib/binary with only 8-bit`n"
        }
        x2652 {
            Write-Output "1 = Lib/binary with Main, Main10 and Main12"
            Write-Output "2 = No"
            Write-Output "3 = Lib/binary with Main10 only"
            Write-Output "4 = Lib/binary with Main only"
            Write-Output "5 = Lib/binary with Main, shared libs with Main10 and Main12"
            Write-Output "6 = Same as 1 with XP support and non-XP compatible x265-numa.exe"
            Write-Output "7 = Lib/binary with Main12 only`n"
        }
        ffmpegB2 {
            Write-Output "1 = Yes [static] [recommended]"
            Write-Output "2 = No"
            Write-Output "3 = Shared"
            Write-Output "4 = Both static and shared [shared goes to an isolated directory]"
            Write-Output "5 = Shared-only with some shared libs (libass, freetype and fribidi)`n"
            Write-Output "Note: Option 5 differs from 3 in that libass, freetype and fribidi are"
            Write-Output "compiled shared so they take less space. This one isn't tested a lot and"
            Write-Output "will fail with fontconfig enabled.`n"
        }
        ffmpegUpdate {
            Write-Output "1 = Yes"
            Write-Output "2 = No"
            Write-Output "3 = Only build FFmpeg/mpv and missing dependencies`n"
            Write-Output "FFmpeg is updated a lot so you only need to select this if you"
            Write-Output "absolutely need updated external libraries in FFmpeg.`n"
        }
        ffmpegChoice {
            Write-Output "1 = Yes"
            Write-Output "2 = No (Light build)"
            Write-Output "3 = No (Mimic Zeranoe)"
            Write-Output "4 = No (All available external libs)`n"
            Write-Output "Avoid the last two unless you're really want useless libraries you'll never use."
            Write-Output "Just because you can include a shitty codec no one uses doesn't mean you should.`n"
            Write-Output "If you select yes, we will create files with the default options"
            Write-Output "we use with FFmpeg and mpv. You can remove any that you don't need or prefix"
            Write-Output "them with #`n"
        }
        mpv {
            Write-Output "1 = Yes"
            Write-Output "2 = No"
            Write-Output "3 = compile with Vapoursynth, if installed [see Warning]`n"
            Write-Output "Note: when built with shared-only FFmpeg, mpv is also shared."
            Write-Output "Note: Requires at least Windows Vista."
            Write-Output "Warning: the third option isn't completely static. There's no way to include"
            Write-Output "a library dependant on Python statically. All users of the compiled binary"
            Write-Output "will need VapourSynth installed using the official package to even open mpv!`n"
        }
        curl {
            Write-Output "1 = Yes [same backend as FFmpeg's]"
            Write-Output "2 = No"
            Write-Output "3 = SChannel backend"
            Write-Output "4 = GnuTLS backend"
            Write-Output "5 = OpenSSL backend"
            Write-Output "6 = LibreSSL backend"
            Write-Output "7 = mbedTLS backend`n"
            Write-Output "A curl-ca-bundle.crt will be created to be used as trusted certificate store"
            Write-Output "for all backends except SChannel.`n"
        }
        cores {
            Write-Output "Recommended: $(
                switch ($env:NUMBER_OF_PROCESSORS) {
                    1 {1}
                    Default {$env:NUMBER_OF_PROCESSORS / 2}
                }
            )`n"
        }
        "deleteSource|strip|logging" {
            Write-Output "1 = Yes [recommended]"
            Write-Output "2 = No`n"
        }
        pack {
            Write-Output "1 = Yes"
            Write-Output "2 = No [recommended]`n"
        }
        Default {
            Write-Output "1 = Yes"
            Write-Output "2 = No`n"
        }
    }
    switch -Regex ($Question) {
        "vpx|aom|x2652" {Write-Output "Binaries being built depends on 'standalone=y'`n"}
        "dav1d|x2643" {Write-Output "Binaries being built depends on 'standalone=y' and are always static.`n"}
        fdkaac {
            Write-Output "Note: FFmpeg's aac encoder is no longer experimental and considered equal or"
            Write-Output "better in quality from 96kbps and above. It still doesn't support AAC-HE/HEv2"
            Write-Output "so if you need that or want better quality at lower bitrates than 96kbps,"
            Write-Output "use FDK-AAC.`n"
        }
        mplayer2 {
            Write-Output "Don't bother opening issues about this if it breaks, I don't fucking care"
            Write-Output "about ancient unmaintained shit code. One more issue open about this that"
            Write-Output "isn't the suite's fault and mplayer goes fucking out.`n"
        }
        ffmbc {
            Write-Output "Note: this is a fork of FFmpeg 0.10. As such, it's very likely to fail"
            Write-Output "to build, work, might burn your computer, kill your children, like mplayer."
            Write-Output "Only enable it if you absolutely need it. If it breaks, complain first to"
            Write-Output "the author in #ffmbc in Freenode IRC.`n"
        }
        deleteSource {Write-Output "This will save a bit of space for libraries not compiled from git/hg/svn.`n"}
        Strip {Write-Output "Makes binaries smaller at only a small time cost after compiling.`n"}
        pack {
            Write-Output "Attention: Some security applications may detect packed binaries as malware."
            Write-Output "Increases delay on runtime during which files need to be unpacked."
            Write-Output "Makes binaries smaller at a big time cost after compiling and on runtime."
            Write-Output "If distributing the files, consider packing them with 7-zip instead.`n"
        }
        logging {
            Write-Output "Note: Setting this to yes will also hide output from these commands."
            Write-Output "On successful compilation, these logs are deleted since they aren't needed.`n"
        }
        updateSuite {
            Write-Output "If you have made changes to the scripts, they will be reset but saved to"
            Write-Output "a .diff text file inside $build`n"
        }
        copybin {Write-Output "Will only copy *.exe within the bin-audio, bin-global, and bin-video."}
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
        if (($jsonObjects.ffmpegB2 -ne 2) -or ($jsonObjects.cyanrip2 -eq 1)) {
            $ffmpegoptions = "$build\ffmpeg_options.txt"
            if (!(Test-Path -PathType Leaf $ffmpegoptions)) {
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
                Write-Output "$("-"*80)"
                Write-Output "File with default FFmpeg options has been created in $ffmpegoptions`n"
                Write-Output "Edit it now or leave it unedited to compile according to defaults."
                Write-Output "$("-"*80)"
                Pause
            }
        }
        if ($jsonObjects.mpv -eq 1) {
            $mpvoptions = "$build\mpv_options.txt"
            if (!(Test-Path -PathType Leaf $mpvoptions)) {
                $(
                    Write-Output "# Lines starting with this character are ignored`n`n# Built-in options, use --disable- to disable them."
                    Write-Option $mpv_options_builtin
                    Write-Output "`n# Common options or overriden defaults"
                    Write-Option $mpv_options_basic
                    Write-Output "`n# Full"
                    Write-Option $mpv_options_full
                ) | Out-File $mpvoptions
                Write-Output "$("-"*80)"
                Write-Output "File with default mpv options has been created in $mpvoptions`n"
                Write-Output "Edit it now or leave it unedited to compile according to defaults."
                Write-Output "$("-"*80)"
                Pause
            }
        }

    }
}

foreach ($a in $jsonObjects.psobject.Properties.Name) {
    if ($a -match "copybin|installdir") {
        if ($jsonObjects.ffmpegB2 -match "1|4") {
            while (1..2 -notcontains $jsonObjects.copybin) {Write-Question "copybin"}
            if ($jsonObjects.copybin -eq 1) {
                while (!(Test-Path variable:installdir)) {
                    try {
                        $installdir = Resolve-Path $jsonObjects.installdir
                    } catch {
                        do {
                            Write-Output "$("-"*80)`n$("-"*80)`n"
                            Write-Output "Where do you want to install the final programs?"
                            Write-Output "Enter a full path such as:"
                            Write-Output "`"C:\test\`""
                            Write-Output "$("-"*80)`n$("-"*80)"
                            $jsonObjects.installdir = (Read-Host -Prompt "Path to final dir: ").Replace('"', '')
                            New-Item -Force -ItemType Directory -Path $jsonObjects.installdir | Out-Null
                        } while (!(Test-Path $jsonObjects.installdir))
                    }
                }
                ConvertTo-Json -InputObject $jsonObjects | Out-File $json
            }
        } else {
            $jsonObjects.copybin = 2
        }
    } else {
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
if ($PSVersionTable.PSVersion.Major -ne 3) {
    Write-Output "$("-"*60)"
    Write-Output "If you want to reuse this console do"
    Write-Output "`$env:Path = `$Global:TempPath"
    Write-Output "else you won't have your original path in this console until you close and reopen."
    Write-Output "$("-"*60)"
}
Start-Sleep -Seconds 2
$Global:TempPath = $env:Path
$env:Path = $($env:Path.Split(';') -match "NVIDIA|Windows" -join ';') + ";$PSScriptRoot\msys64\usr\bin"
$msys2Path = "$PSScriptRoot\$msys2"
$bash = "$msys2Path\usr\bin\bash.exe"
$msysprefix = switch ([System.IntPtr]::Size) {
    4 {"i686"}
    Default {"x86_64"}
}

if (!(Test-Path $msys2Path\msys2_shell.cmd)) {
    Set-Location $build
    if (!(Test-Path $build\7za.exe)) {
        try {
            Write-Output "$("-"*60)`n`n- Downloading Wget`n`n$("-"*60)"
            $progressPreference = 'silentlyContinue'
            switch ($PSVersionTable.PSVersion.Major) {
                6 {
                    switch ((Test-Connection -ComputerName i.fsbn.eu -Count 1 -ErrorAction Ignore -InformationAction Ignore).Replies.RoundTripTime) {
                        0 {$null}
                        Default {$fsbnping = $_}
                    }
                    switch ((Test-Connection -ComputerName randomderp.com -Count 1 -ErrorAction Ignore -InformationAction Ignore).Replies.RoundTripTime) {
                        0 {$null}
                        Default {$rdpping = $_}
                    }
                }
                Default {
                    $fsbnping = (Test-Connection -ComputerName i.fsbn.eu -Count 1 -InformationAction Ignore -ErrorAction Ignore).ResponseTime
                    $rdpping = (Test-Connection -ComputerName randomderp.com -Count 1 -InformationAction Ignore -ErrorAction Ignore).ResponseTime
                }
            }
            switch (Test-Path variable:fsbnping) {
                $true {
                    switch (Test-Path variable:rdpping) {
                        $true {
                            if ($fsbnping -le $rdpping) {
                                Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://i.fsbn.eu/pub/wget-pack.exe"
                            } else {
                                Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://randomderp.com/wget-pack.exe"
                            }
                        }
                        $false {Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://i.fsbn.eu/pub/wget-pack.exe"}
                    }
                }
                $false {
                    switch (Test-Path variable:$rdpping) {
                        $true {Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://randomderp.com/wget-pack.exe"}
                        $false {throw}
                    }
                }
            }
            if ((Get-FileHash -Path $build\wget-pack.exe).Hash -eq "3F226318A73987227674A4FEDDE47DF07E85A48744A07C7F6CDD4F908EF28947") {
                Start-Process -Wait -NoNewWindow -FilePath $build\wget-pack.exe  -WorkingDirectory $build
            } else {
                throw
            }
        } catch {
            Write-Output "$("-"*60)`n"
            Write-Output "Script to download necessary components failed.`n"
            Write-Output "Download and extract this manually to inside $($build):"
            Write-Output "https://i.fsbn.eu/pub/wget-pack.exe`n"
            Write-Output "$("-"*60)"
            Pause
            exit
        } finally {
            Remove-Item $build\wget-pack.exe 2>$null
            $progressPreference = 'Continue'
        }
    }
    Write-Output "$("-"*60)`n`n- Download and install msys2 basic system`n`n$("-"*60)"
    try {
        if ((Test-Path $env:TEMP\msys2-base.tar.xz) -and ((Get-Item $env:TEMP\msys2-base.tar.xz).Length -eq (Invoke-WebRequest -Uri "http://repo.msys2.org/distrib/msys2-$($msysprefix)-latest.tar.xz" -UseBasicParsing -Method Head).headers.'Content-Length')) {
        } else {
            Remove-Item $env:TEMP\msys2-base.tar.xz -ErrorAction Ignore
            Invoke-WebRequest -OutFile $env:TEMP\msys2-base.tar.xz -Uri "http://repo.msys2.org/distrib/msys2-$($msysprefix)-latest.tar.xz"
        }
        Copy-Item $env:TEMP\msys2-base.tar.xz $build\msys2-base.tar.xz
        Start-Process -Wait -NoNewWindow -FilePath $build\7za.exe -ArgumentList "x -aoa msys2-base.tar.xz" -WorkingDirectory $build
        if (-not $? -or $LASTEXITCODE -ne 0) {throw}
        Remove-Item $build\msys2-base.tar.xz -ErrorAction Ignore
        Start-Process -Wait -NoNewWindow -FilePath $build\7za.exe -ArgumentList "x -aoa msys2-base.tar" -WorkingDirectory $build
        if (-not $? -or $LASTEXITCODE -ne 0) {throw}
        Remove-Item $build\msys2-base.tar
        Move-Item -Path $build\msys64 $PSScriptRoot
    } catch {
        Write-Output "$("-"*60)`n"
        Write-Output "- Download msys2 basic system failed,"
        Write-Output "- please download it manually from:"
        Write-Output "- http://repo.msys2.org/distrib/"
        Write-Output "- and copy the uncompressed folder to:"
        Write-Output "- $build"
        Write-Output "- and start the script again!`n"
        Write-Output "$("-"*60)"
        pause
        exit
    }
}

$fstab = Resolve-Path $msys2Path\etc\fstab
# createFolders
function Write-BaseFolders ([int]$bit) {
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
function Write-Fstab {
    Write-Output "$("-"*60)`n`n- write fstab mount file`n`n$("-"*60)"
    $fstabtext = "none / cygdrive binary,posix=0,noacl,user 0 0`n$PSScriptRoot\ /trunk`n$PSScriptRoot\build\ /build`n$msys2Path\mingw32\ /mingw32`n$msys2Path\mingw64\ /mingw64`n"
    if ($build32 -eq "yes") {$fstabtext += "$PSScriptRoot\local32\ /local32`n"}
    if ($build64 -eq "yes") {$fstabtext += "$PSScriptRoot\local64\ /local64`n"}
    New-Item -Force -ItemType File -Path $fstab -Value $fstabtext | Out-Null
}
function Write-Log ($logfile, [ScriptBlock]$ScriptBlock) {
    try {
        Start-Transcript -Force -Path $logfile | Out-Null
        &$ScriptBlock
    } catch {
        Write-Output "Stopping logging and exiting"
    } finally {
        Stop-Transcript | Out-Null
        Set-Content -Path $logfile -Value $(Get-Content $logfile | Where-Object {$_ -notmatch "Username|RunAs|Machine|Host Application"})
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
    Write-Log -logfile $build\firstrun.log -ScriptBlock {
        Write-Output "$("-"*60)`n- make a first run`n$("-"*60)"
        Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc exit"
    }
    Write-Fstab
    Write-Log -logfile $build\firstUpdate.log -ScriptBlock {
        Write-Output "$("-"*60)`nFirst update`n$("-"*60)"
        Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc 'pacman -Sy --needed --ask=20 --noconfirm --asdeps pacman-mirrors'"

    }
    Write-Log -logfile $build\criticalUpdate.log -ScriptBlock {
        Write-Output "$("-"*60)`ncritical updates`n$("-"*60)"
        Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc 'pacman -S --needed --ask=20 --noconfirm --asdeps bash pacman msys2-runtime'"
    }
    Write-Log -logfile $build\secondUpdate.log -ScriptBlock {
        Write-Output "$("-"*60)`nsecond update`n$("-"*60)"
        Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc 'pacman -Syu --needed --ask=20 --noconfirm --asdeps'"
    }
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
    Write-Log -logfile $build\pacman.log -ScriptBlock {
        Write-Output "$("-"*60)`ninstall msys2 base system`n$("-"*60)"
        Remove-Item -Force $build\install_base_failed -ErrorAction Ignore
        New-Item -Force -ItemType File -Path $msys2Path\etc\pac-base.temp -Value $($msyspackages | ForEach-Object {"$_"} | Out-String) | Out-Null
        (Get-Content $msys2Path\etc\pac-base.temp -Raw).Replace("`r", "") | Set-Content $msys2Path\etc\pac-base.temp -Force -NoNewline
        Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc 'pacman -Sw --noconfirm --ask=20 --needed - < /etc/pac-base.temp; pacman -S --noconfirm --ask=20 --needed - < /etc/pac-base.temp && pacman -D --asexplicit --noconfirm --ask=20 - < /etc/pac-base.temp'"
        Remove-Item $msys2Path\etc\pac-base.temp -ErrorAction Ignore
    }
}

if (!(Test-Path $msys2Path\usr\ssl\cert.pem)) {Write-Log -logfile $build\cert.log -ScriptBlock {Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc update-ca-trust"}}
if (!(Test-Path "$msys2Path\usr\bin\hg.bat")) {New-Item -Force -ItemType File -Path $msys2Path\usr\bin\hg.bat -Value "`@echo off`r`n`r`nsetlocal`r`nset HG=%~f0`r`n`r`nset PYTHONHOME=`r`nset in=%*`r`nset out=%in: {= `"{%`r`nset out=%out:} =}`" %`r`n`r`n%~dp0python2 %~dp0hg %out%" | Out-Null}

Remove-Item -Force $msys2Path\etc\pac-mingw.pk -ErrorAction Ignore
foreach ($i in $mingwpackages) {Write-Output "$i" | Out-File -Append $msys2Path\etc\pac-mingw.pk}

function Get-Compiler ([int]$bit) {
    Write-Log -logfile $build\mingw$($bit).log -ScriptBlock {
        Write-Output "$("-"*60)`ninstall $bit bit compiler`n$("-"*60)"
        New-Item -Force -ItemType File -Path $msys2Path\etc\pac-mingw.temp -Value $($mingwpackages | ForEach-Object {"mingw-w64-$($msysprefix)-$_"} | Out-String) | Out-Null
        (Get-Content $msys2Path\etc\pac-mingw.temp -Raw).Replace("`r", "") | Set-Content $msys2Path\etc\pac-mingw.temp -Force -NoNewline
        Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc 'pacman -Sw --noconfirm --ask=20 --needed - < /etc/pac-mingw.temp; pacman -S --noconfirm --ask=20 --needed - < /etc/pac-mingw.temp; pacman -D --asexplicit --noconfirm --ask=20 - < /etc/pac-mingw.temp'"
        if (!(Test-Path $msys2Path\mingw$($bit)\bin\gcc.exe)) {
            Write-Output "$("-"*60)`nMinGW$($bit) GCC compiler isn't installed; maybe the download didn't work`nDo you want to try it again?`n$("-"*60)"
            if ($(Read-Host -Prompt "try again [y/n]: ") -eq "y") {
                Get-Compiler -bit $bit
            } else {
                exit
            }
        } else {
            Remove-Item $msys2Path\etc\pac-mingw.temp -ErrorAction Ignore
        }
    }
}
if (($build32 -eq "yes") -and !(Test-Path $msys2Path\mingw32\bin\gcc.exe)) {Get-Compiler -bit 32}
if (($build64 -eq "yes") -and !(Test-Path $msys2Path\mingw64\bin\gcc.exe)) {Get-Compiler -bit 64}

# updatebase
Write-Output "$("-"*60)`nupdate autobuild suite`n$("-"*60)"
"compile", "helper", "update" | ForEach-Object {if (!(Test-Path $build\media-suite_$($_).sh)) {Invoke-WebRequest -OutFile $build\media-suite_$($_).sh -Uri "https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/media-suite_$($_).sh"}}

if ($jsonObjects.updateSuite -eq 1) {
    Write-Output "$("-"*60)"
    Write-Output "Creating suite update file...`n"
    Write-Output "Run this file by dragging it to mintty before the next time you run"
    Write-Output "the suite and before reporting an issue.`n"
    Write-Output "It needs to be run separately and with the suite not running!"
    Write-Output "$("-"*60)"
    $(
        Write-Output "#!/bin/bash`n`n# Run this file by dragging it to mintty shortcut.`n# Be sure the suite is not running before using it!`n`nupdate=yes`n"
        Get-Content $build\media-suite_update.sh | Select-Object -Index ($((Select-String -Path $build\media-suite_update.sh -Pattern "start suite update").LineNumber)..$((Select-String -Path $build\media-suite_update.sh -Pattern "end suite update").LineNumber)) | ForEach-Object {$_ + "`n"}
    ) | Out-File -NoNewline -Force $PSScriptRoot\update_suite.sh
}

# update
Write-Log -logfile $build\update.log -ScriptBlock {Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-l /build/media-suite_update.sh --build32=$build32 --build64=$build64"}
if (Test-Path $build\update_core) {
    Write-Log -logfile $build\update_core.log -ScriptBlock {
        Write-Output "$("-"*60)`ncritical updates`n$("-"*60)"
        Start-Process -Wait -NoNewWindow -FilePath $bash -ArgumentList "-lc 'pacman -Syyu --needed --noconfirm --ask=20 --asdeps'"
        Remove-Item $build\update_core
    }
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
Remove-Item $env:TEMP\msys2-base.tar.xz -ErrorAction Ignore

if (Test-Path $msys2Path\etc\profile.pacnew) {Move-Item -Force $msys2Path\etc\profile.pacnew $msys2Path\etc\profile}
if (!(Select-String -Pattern "profile2.local" -Path $msys2Path\etc\profile)) {New-Item -Force -ItemType File -Path $msys2Path\etc\profile.d\Zab-suite.sh -Value "if [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW64 ]]; then`n   source /local64/etc/profile2.local`nelif [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW32 ]]; then`n   source /local32/etc/profile2.local`nfi" | Out-Null}

# compileLocals
$MSYSTEM = switch ($build64) {
    yes {"MINGW64"}
    Default {"MINGW32"}
}
Set-Location $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "MABSbat"
Write-Log -logfile $build\compile.log -ScriptBlock {
    Start-Process -Wait -NoNewWindow -FilePath $msys2Path\usr\bin\env -ArgumentList "MSYSTEM=$MSYSTEM MSYS2_PATH_TYPE=inherit /usr/bin/bash -l /build/media-suite_compile.sh --cpuCount=$cores --build32=$build32 --build64=$build64 --deleteSource=$deleteSource --mp4box=$mp4box --vpx=$vpx2 --x264=$x2643 --x265=$x2652 --other265=$other265 --flac=$flac --fdkaac=$fdkaac --mediainfo=$mediainfo --sox=$soxB --ffmpeg=$ffmpeg --ffmpegUpdate=$ffmpegUpdate --ffmpegChoice=$ffmpegChoice --mplayer=$mplayer2 --mpv=$mpv --license=$license2 --stripping=$strip --packing=$pack --rtmpdump=$rtmpdump --logging=$logging --bmx=$bmx --standalone=$standalone --aom=$aom --faac=$faac --ffmbc=$ffmbc --curl=$curl --cyanrip=$cyanrip2 --redshift=$redshift --rav1e=$rav1e --ripgrep=$ripgrep --dav1d=$dav1d --vvc=$vvc --jq=$jq --dssim=$dssim"
}
$env:Path = $Global:TempPath