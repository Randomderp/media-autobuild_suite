#!/usr/bin/env powershell

$PSDefaultParameterValues["Out-File:Encoding"] = "UTF8"

# Some functions do not have any counter parts in ps version below 3, aka XP, 2003, 2008. Windows XP doesn't even have pause... This section will fail with an error... :crying:
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "Your Powershell version is too low!"
    Write-Host "Please update your version either through an OS update"
    Write-Host "or download the latest version for your system from"
    Write-Host "https://github.com/PowerShell/PowerShell"
    Pause
    exit
}
#requires -Version 3.0.0

# Temporarily store the Path
$tempPath = $env:Path

# Set window title
$Host.UI.RawUI.WindowTitle = "media-autobuild_suite"

# Place where the script is, main directory
$instdir = $PSScriptRoot

# Check if directory has spaces, may be unecessary depending on what requires no space paths
if (($instdir) -match " ") {
    Write-Host "----------------------------------------------------------------------"
    Write-Host "You have probably run the script in a path with spaces.`n"
    Write-Host "This is not supported.`n"
    Write-Host "Please move the script to use a path without spaces. Example:`n"
    Write-Host "Incorrect: C:\build suite\`n"
    Write-Host "Correct:   C:\build_suite\`n"
    Pause
    exit
}
elseif (($instdir).Length -gt 60) {
    # Check if directory path is longer than 60 characters, may be unecessary depending on what requires paths shorter than 60
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
    Set-Location $instdir
}

# Set bitness, not build bit. Eq to _bitness, may be useless as it seemed to only be used to decide the msys2Arch
#$bitness = switch ([System.IntPtr]::Size) {
#    4 {32}
#    Default {64}
#}

# Set Build path
$build = "$($instdir)\build"
if (-Not (Test-Path $build -PathType Container)) {
    mkdir -Name "build" -Path $instdir 2>&1 | Out-Null
}

# Set package variables
# change ini options to PSObject+json later
$msyspackages = "asciidoc", "autoconf", "automake-wrapper", "autogen", "bison", "diffstat", "dos2unix", "help2man", "intltool", "libtool", "patch", "python", "xmlto", "make", "zip", "unzip", "git", "subversion", "wget", "p7zip", "mercurial", "man-db", "gperf", "winpty", "texinfo", "gyp-git", "doxygen", "autoconf-archive", "itstool", "ruby", "mintty"
$mingwpackages = "cmake", "dlfcn", "libpng", "gcc", "nasm", "pcre", "tools-git", "yasm", "ninja", "pkg-config", "meson"
$ffmpeg_options_builtin = "--disable-autodetect", "amf", "bzlib", "cuda", "cuvid", "d3d11va", "dxva2", "iconv", "lzma", "nvenc", "schannel", "zlib", "sdl2", "--disable-debug", "ffnvcodec", "nvdec"
$ffmpeg_options_basic = "gmp", "libmp3lame", "libopus", "libvorbis", "libvpx", "libx264", "libx265", "libdav1d"
$ffmpeg_options_zeranoe = "fontconfig", "gnutls", "libass", "libbluray", "libfreetype", "libmfx", "libmysofa", "libopencore-amrnb", "libopencore-amrwb", "libopenjpeg", "libsnappy", "libsoxr", "libspeex", "libtheora", "libtwolame", "libvidstab", "libvo-amrwbenc", "libwavpack", "libwebp", "libxml2", "libzimg", "libshine", "gpl", "openssl", "libtls", "avisynth", "mbedtls", "libxvid", "libaom", "version3"
$ffmpeg_options_full = "chromaprint", "cuda-sdk", "decklink", "frei0r", "libbs2b", "libcaca", "libcdio", "libfdk-aac", "libflite", "libfribidi", "libgme", "libgsm", "libilbc", "libkvazaar", "libmodplug", "libnpp", "libopenh264", "libopenmpt", "librtmp", "librubberband", "libssh", "libtesseract", "libxavs", "libzmq", "libzvbi", "opencl", "opengl", "libvmaf", "libcodec2", "libsrt", "ladspa", "#vapoursynth", "#liblensfun", "libndi_newtek"
$mpv_options_builtin = "#cplayer", "#manpage-build", "#lua", "#javascript", "#libass", "#libbluray", "#uchardet", "#rubberband", "#lcms2", "#libarchive", "#libavdevice", "#shaderc", "#crossc", "#d3d11", "#jpeg"
$mpv_options_basic = "--disable-debug-build", "--lua=luajit"
$mpv_options_full = "dvdread", "dvdnav", "cdda", "egl-angle", "vapoursynth", "html-build", "pdf-build", "libmpv-shared"

$jsonObjects = [PSCustomObject]@{
    msys2Arch      = switch ([System.IntPtr]::Size) {
        4 {1}
        default {2}
    }
    arch           = 0
    license2       = 0
    standalone     = 0
    vpx2           = 0
    aom            = 0
    rav1e          = 0
    dav1d          = 0
    x2643          = 0
    x2652          = 0
    other265       = 0
    vvc            = 0
    flac           = 0
    fdkaac         = 0
    faac           = 0
    mediainfo      = 0
    soxB           = 0
    ffmpegB2       = 0
    ffmpegUpdate   = 0
    ffmpegChoice   = 0
    mp4box         = 0
    rtmpdump       = 0
    mplayer2       = 0
    mpv            = 0
    bmx            = 0
    curl           = 0
    ffmbc          = 0
    cyanrip2       = 0
    redshift       = 0
    ripgrep        = 0
    cores          = 0
    deleteSource   = 0
    strip          = 0
    pack           = 0
    logging        = 0
    updateSuite    = 0
    forceQuitBatch = 0
}
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
    46 = "forceQuitBatch"
}
$writeProperties = $false

#$previousOptions = $false # redundant, probably
#$msys2ArchINI = 0 # also redundant, probably
$json = "$build\media-autobuild_suite.json"
$coresrecommend = switch ((Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors) {
    1 {1}
    Default {
        (Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors / 2
    }
}

if (Test-Path -Path $json) {
    $jsonProperties = Get-Content $json | ConvertFrom-Json
    foreach ($a in (Get-Member -InputObject $jsonObjects -MemberType NoteProperty | Select-Object -ExpandProperty Name)) {
        if ($jsonProperties.$a -ne 0) {
            $jsonObjects.$a = $jsonProperties.$a
        }
        else {
            $writeProperties = $true
        }
    }
}
else {
    #initialize json file
    $jsonObjects | ConvertTo-Json | Out-File $json

    $writeProperties = $true
}

#Select-Object -InputObject $jsonObjects -Property $a

# sytemVars
foreach ($b in (Get-Member -InputObject $order -MemberType NoteProperty | Select-Object -ExpandProperty Name)) {
    $a = Get-Member -Name $($order.$b) -InputObject $jsonObjects | Select-Object -ExpandProperty Name
    if ($a -eq "msys2Arch") {
        $msys2 = switch ($jsonObjects.msys2Arch) {
            1 {"msys32"}
            2 {"msys64"}
        }
    }
    elseif (0 -eq ($jsonObjects.$("$a"))) {
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
                    cores {99}
                    Default {2}
                }
            ) -notcontains $jsonObjects.$("$a")) {
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
                    # Still don't understand why the for /l loop on 1,1,%cpuCores%
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
                forceQuitBatch {
                    Write-Host "Force quit this batch window after launching compilation script?"
                    Write-Host "This will forcibly close this batch window. Only use this if you have the issue"
                    Write-Host "where the window doesn't close after launching the compilation script.`n"
                }
                Default {}
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
                    Write-Host "Recommended: $coresrecommend`n"
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
            $jsonObjects.$("$a") = [int](
                Read-Host -Prompt $(
                    switch ($a) {
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
                        forceQuitBatch {"Forcefully close batch: "}
                        Default {"Build $($a): "}
                    }
                )
            )
        }
        if ($writeProperties) {
            ConvertTo-Json -InputObject $jsonObjects | Out-File $json
        }
        switch ($a) {
            arch {
                switch ($jsonObjects.arch) {
                    1 {
                        $build32 = "yes"
                        $build64 = "yes"
                    }
                    2 {
                        $build32 = "yes"
                        $build64 = "no"
                    }
                    3 {
                        $build32 = "no"
                        $build64 = "yes"
                    }
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
                        if (-Not (Test-Path -PathType Leaf $ffmpegoptions)) {
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
                        if (-Not (Test-Path -PathType Leaf $mpvoptions)) {
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
}

# EOQuestions

# msys2 system
if (-Not (Test-Path $instdir\$msys2\usr\bin\wget.exe)) {
    Write-Host "-------------------------------------------------------------`n"
    Write-Host "- Downloading Wget`n"
    Write-Host "-------------------------------------------------------------"
    Set-Location $build
    if ((-Not (Test-Path $build\7za.exe)) -or (-Not (Test-Path $build\grep.exe))) {
        while (-Not (Test-Path $build\wget.exe)) {
            $progressPreference = 'silentlyContinue'
            if (Test-Connection -Quiet -ComputerName i.fsbn.eu -Count 1 6>$null 2>$null) {
                Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://i.fsbn.eu/pub/wget-pack.exe"
            }
            elseif (Test-Connection -Quiet -ComputerName randomderp.com -Count 1 6>$null 2>$null) {
                Invoke-WebRequest -OutFile "$build\wget-pack.exe" -Uri "https://randomderp.com/wget-pack.exe"
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
            $wgetHash = (Get-FileHash -Algorithm SHA256 -Path "$build\wget-pack.exe").hash
            if ($wgetHash -eq "3F226318A73987227674A4FEDDE47DF07E85A48744A07C7F6CDD4F908EF28947") {
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

if (-Not (Test-Path $instdir\$msys2\msys2_shell.cmd)) {
    Write-Host "-------------------------------------------------------------`n"
    Write-Host "- Download and install msys2 basic system`n"
    Write-Host "-------------------------------------------------------------"
    $msysprefix = switch ($msys2) {
        msys32 {"i686"}
        Default {"x86_64"}
    }
    Start-Process -WorkingDirectory $build -Wait -NoNewWindow -FilePath $build\wget.exe -ArgumentList "--tries=5 --retry-connrefused --waitretry=5 --continue -O `"msys2-base.tar.xz`" `"http://repo.msys2.org/distrib/msys2-$($msysprefix)-latest.tar.xz`""

}
if (Test-Path $build\msys2-base.tar.xz) {
    # I hate how I can't use pipes similar to *nix
    Start-Process -WorkingDirectory $build -Wait -NoNewWindow -FilePath $build\7za.exe -ArgumentList "x -aoa msys2-base.tar.xz"
    Start-Process -WorkingDirectory $build -Wait -NoNewWindow -FilePath $build\7za.exe -ArgumentList "x -aoa msys2-base.tar -o.."
    Remove-Item $build\msys2-base.tar
    Remove-Item $build\msys2-base.tar.xz
}
if (-Not (Test-Path $instdir\$msys2\usr\bin\msys-2.0.dll)) {
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

$mintty = "$instdir\$msys2\usr\bin\mintty.exe"
$defaultMintty = "-d -i /msys2.ico "
if (-Not (Test-Path $instdir\mintty.link)) {
    if ($msys2 -eq "msys32") {
        Write-Host "-------------------------------------------------------------`n"
        Write-Host "rebase $msys2 system`n"
        Write-Host "-------------------------------------------------------------"
        Start-Process -Wait -NoNewWindow -FilePath $instdir\$msys2\autorebase.bat
    }
    Write-Host "-------------------------------------------------------------"
    Write-Host "- make a first run"
    Write-Host "-------------------------------------------------------------"
    if (Test-Path $build\firstrun.log) {
        Remove-Item $build\firstrun.log
    }
    Start-Process -Wait -NoNewWindow -FilePath $mintty -ArgumentList $($defaultMintty + "--log $build\firstrun.log /usr/bin/bash --login -c exit")

    Write-Host "-------------------------------------------------------------"
    Write-Host "First update"
    Write-Host "-------------------------------------------------------------"
    $(
        Write-Output "echo -ne `"\033]0;first msys2 update\007`""
        Write-Output "pacman --noconfirm -Sy --asdeps pacman-mirrors"
        Write-Output "sed -i `"s;^^IgnorePkg.*;#&;`" /etc/pacman.conf"
        Write-Output "sleep 4`nexit"
    )| Out-File $build\firstUpdate.sh
    if (Test-Path $build\firstUpdate.log) {
        Remove-Item $build\firstUpdate.log
    }
    Start-Process -Wait -NoNewWindow -FilePath $mintty -ArgumentList $($defaultMintty + "--log $build\firstUpdate.log /usr/bin/bash --login $build\firstUpdate.sh")
    Remove-Item $build\firstUpdate.sh

    Write-Host "-------------------------------------------------------------"
    Write-Host "critical updates"
    Write-Host "-------------------------------------------------------------"
    Start-Process -NoNewWindow -Wait -FilePath $instdir\$msys2\usr\bin\sh.exe -ArgumentList '-lc "pacman -S --needed --ask=20 --noconfirm --asdeps bash pacman msys2-runtime"'

    Write-Host "-------------------------------------------------------------"
    Write-Host "second update"
    Write-Host "-------------------------------------------------------------"
    $(
        Write-Output "echo -ne `"\033]0;second msys2 update\007`"`r`npacman --noconfirm -Syu --asdeps`r`nexit"
    ) | Out-File $build\secondUpdate.sh
    if (Test-Path $build\secondUpdate.log) {
        Remove-Item $build\secondUpdate.log
    }
    Start-Process -Wait -NoNewWindow -FilePath $mintty -ArgumentList $($defaultMintty + "--log $build\secondUpdate.log /usr/bin/bash --login $build\secondUpdate.sh")
    Remove-Item $build\secondUpdate.sh

    $(
        Write-Output "Set Shell = CreateObject(`"WScript.Shell`")"
        Write-Output "Set link = Shell.CreateShortcut(`"$instdir\mintty.lnk`")"
        Write-Output "link.Arguments = `"-full-path -mingw`""
        Write-Output "link.Description = `"msys2 shell console`""
        Write-Output "link.TargetPath = `"$instdir\$msys2\msys2_shell.cmd`""
        Write-Output "link.WindowStyle = 1"
        Write-Output "link.IconLocation = `"$instdir\$msys2\msys2.ico`""
        Write-Output "link.WorkingDirectory = `"$instdir\$msys2`""
        Write-Output "link.Save"
    ) | Out-File $build\setlink.vbs
    Start-Process -NoNewWindow -Wait -ArgumentList "/nologo $build\setlink.vbs" cscript
    Remove-Item $build\setlink.vbs
}
if (-Not (Test-Path $instdir\$msys2\home\$env:UserName)) {
    mkdir $instdir\$msys2\home\$env:UserName
}

if (-Not (Test-Path $instdir\$msys2\home\$env:UserName\.minttyrc)) {
    $(
        Write-Output "printf '%s\n' Locale=en_US Charset=UTF-8 Font=Consolas Columns=120 Rows=30 > /home/$env:UserName/.minttyrc"
    ) | Out-File $build\mintty.sh
    Start-Process -Wait -NoNewWindow -FilePath $mintty -ArgumentList $($defaultMintty + "/usr/bin/bash --login $build\mintty.sh")
    Remove-Item $build\mintty.sh
}

if (-Not (Test-Path $instdir\$msys2\home\$env:UserName\.hgrc)) {
    $(
        Write-Output "[ui]"
        Write-Output "username = $env:UserName"
        Write-Output "verbose = True"
        Write-Output "editor = vim`r`n"
        Write-Output "[web]"
        Write-Output "cacerts=/usr/ssl/cert.pem`r`n"
        Write-Output "[extensions]"
        Write-Output "color =`r`n"
        Write-Output "[color]"
        Write-Output "status.modified = magenta bold"
        Write-Output "status.added = green bold"
        Write-Output "status.removed = red bold"
        Write-Output "status.deleted = cyan bold"
        Write-Output "status.unknown = blue bold"
        Write-Output "status.ignored = black bold"
    ) | Out-File $instdir\$msys2\home\$env:UserName\.hgrc
}

if (-Not (Test-Path $instdir\$msys2\home\$env:UserName\.gitconfig)) {
    $(
        Write-Output "[user]"
        Write-Output "name = $env:UserName"
        Write-Output "email = $env:UserName@$env:COMPUTERNAME`r`n"
        Write-Output "[color]"
        Write-Output "ui = true`r`n"
        Write-Output "[core]"
        Write-Output "editor = vim"
        Write-Output "autocrlf =`r`n"
        Write-Output "[merge]"
        Write-Output "tool = vimdiff`r`n"
        Write-Output "[push]"
        Write-Output "default = simple"
    ) | Out-File $instdir\$msys2\home\$env:UserName\.gitconfig
}

if (Test-Path $instdir\$msys2\etc\pac-base.pk) {
    Remove-Item $instdir\$msys2\etc\pac-base.pk
}
foreach ($i in $msyspackages) {
    Write-Output "$i" | Out-File -Append $instdir\$msys2\etc\pac-base.pk
}

if (-Not (Test-Path $instdir\$msys2\usr\bin\make.exe)) {
    Write-Host "-------------------------------------------------------------"
    Write-Host "install msys2 base system"
    Write-Host "-------------------------------------------------------------"
    if (Test-Path $build\install_base_failed) {
        Remove-Item $build\install_base_failed
    }
    $(
        Write-Output "echo -ne `"\033]0;install base system\007`""
        Write-Output "msysbasesystem=`"`$(cat /etc/pac-base.pk | tr '\n\r' '  ')`""
        Write-Output "[[ `"`$(uname)`" = *6.1* ]] && nargs=`"-n 4`""
        Write-Output "echo `$msysbasesystem | xargs `$nargs pacman -Sw --noconfirm --ask=20 --needed"
        Write-Output "echo `$msysbasesystem | xargs `$nargs pacman -S --noconfirm --ask=20 --needed"
        Write-Output "echo `$msysbasesystem | xargs `$nargs pacman -D --asexplicit"
        Write-Output "sleep 3"
        Write-Output "exit"
    ) | Out-File $build\pacman.sh
    if (Test-Path $build\pacman.log) {
        Remove-Item $build\pacman.log
    }
    Start-Process -NoNewWindow -Wait -FilePath $mintty -ArgumentList $($defaultMintty + "--log $build\pacman.log /usr/bin/bash --login $build\pacman.sh")
    Remove-Item $build\pacman.sh
}

if ((Get-Item -Path $instdir\$msys2\usr\ssl\cert.pem).Length -eq 0) {
    $(
        Write-Output "update-ca-trust"
        Write-Output "sleep 3"
        Write-Output "exit"
    ) | Out-File -$build\cert.sh
    if (Test-Path $build\cert.log) {
        Remove-Item $build\cert.log
    }
    Start-Process -Wait -NoNewWindow -FilePath $mintty -ArgumentList $($defaultMintty + "--log $build\cert.log /usr/bin/bash --login $build\cert.sh")
}

if (-Not (Test-Path $instdir\$msys2\usr\bin\hg.bat)) {
    $(
        Write-Output "@echo off`n"
        Write-Output "setlocal"
        Write-Output "set HG=%~f0`n"
        Write-Output "set PYTHONHOME="
        Write-Output "set in=%*"
        Write-Output "set out=%in: {= `"{%"
        Write-Output "set out=%out:} =}`" %`n"
        Write-Output "%~dp0python2 %~dp0hg %out%"
    ) | Out-File $instdir\$msys2\usr\bin\hg.bat
}

if (Test-Path $instdir\$msys2\etc\pac-mingw.pk) {
    Remove-Item $instdir\$msys2\etc\pac-mingw.pk
}
foreach ($i in $mingwpackages) {
    Write-Output "$i" | Out-File -Append $instdir\$msys2\etc\pac-mingw.pk
}
function Get-32compiler {
    Write-Host "-------------------------------------------------------------"
    Write-Host "install 32 bit compiler"
    Write-Host "-------------------------------------------------------------"
    $(
        Write-Output "echo -ne `"\033]0;install 32 bit compiler\007`""
        Write-Output "mingw32compiler=`"$`(cat /etc/pac-mingw.pk | sed 's;.*;mingw-w64-i686-&;g' | tr '\n\r' '  ')`""
        Write-Output "[[ `"`$(uname)`" = *6.1* ]] && nargs=`"-n 4`""
        Write-Output "echo `$mingw32compiler | xargs `$nargs pacman -Sw --noconfirm --ask=20 --needed"
        Write-Output "echo `$mingw32compiler | xargs `$nargs pacman -S --noconfirm --ask=20 --needed"
        Write-Output "sleep 3"
        Write-Output "exit"
    ) | Out-File $build\mingw32.sh
    if (Test-Path $build\mingw32.log) {
        Remove-Item $build\mingw32.log
    }
    Start-Process -NoNewWindow -Wait -FilePath $mintty -ArgumentList $($defaultMintty + "--log $build\mingw32.log /usr/bin/bash --login $build\mingw32.sh")
    Remove-Item $build\mingw32.sh
}

function Get-64compiler {
    Write-Host "-------------------------------------------------------------"
    Write-Host "install 64 bit compiler"
    Write-Host "-------------------------------------------------------------"
    $(
        Write-Output "echo -ne `"\033]0; install 64 bit compiler\007`""
        Write-Output "mingw64compiler=`"`$(cat /etc/pac-mingw.pk | sed 's;.*;mingw-w64-x86_64-&;g' | tr '\n\r' '  ')`""
        Write-Output "[[ `"`$(uname)`" = *6.1* ]] && nargs=`"-n 4`""
        Write-Output "echo `$mingw64compiler | xargs `$nargs pacman -Sw --noconfirm --ask=20 --needed"
        Write-Output "echo `$mingw64compiler | xargs `$nargs pacman -S --noconfirm --ask=20 --needed"
        Write-Output "sleep 3"
        Write-Output "exit"
    ) | Out-File $build\mingw64.sh
    if (Test-Path $build\mingw64.log) {
        Remove-Item $build\mingw64.log
    }
    Start-Process -NoNewWindow -Wait -FilePath $mintty -ArgumentList $($defaultMintty + "--log $build\mingw64.log /usr/bin/bash --login $build\mingw64.sh")
    Remove-Item $build\mingw64.sh
}

if ($build32 -eq "yes") {
    if (-Not (Test-Path $instdir\$msys2\mingw32\bin\gcc.exe)) {
        Get-32compiler
        if (-Not (Test-Path $instdir\$msys2\mingw32\bin\gcc.exe)) {
            Write-Host "-------------------------------------------------------------"
            Write-Host "MinGW32 GCC compiler isn't installed; maybe the download didn't work"
            Write-Host "Do you want to try it again?"
            Write-Host "-------------------------------------------------------------"
            if ($(Read-Host -Prompt "try again [y/n]: ") -eq "y") {
                Get-32compiler
            }
            else {
                exit
            }
        }
    }
}

if ($build64 -eq "yes") {
    if (-Not (Test-Path $instdir\$msys2\mingw64\bin\gcc.exe)) {
        Get-64compiler
        if (-Not (Test-Path $instdir\$msys2\mingw64\bin\gcc.exe)) {
            Write-Host "-------------------------------------------------------------"
            Write-Host "MinGW64 GCC compiler isn't installed; maybe the download didn't work"
            Write-Host "Do you want to try it again?"
            Write-Host "-------------------------------------------------------------"
            if ($(Read-Host -Prompt "try again [y/n]: ") -eq "y") {
                Get-64compiler
            }
            else {
                exit
            }
        }
    }
}

# updatebase
Write-Host "-------------------------------------------------------------"
Write-Host "update autobuild suite"
Write-Host "-------------------------------------------------------------"
Set-Location $build
$scripts = "compile", "helper", "update"
foreach ($s in $scripts) {
    if (-Not (Test-Path $build\media-suite_$($s).sh)) {
        Start-Process -NoNewWindow -Wait -FilePath $instdir\$msyspackages\usr\bin\wget.exe -ArgumentList "-t 20 --retry-connrefused --waitretry=2 -c https://github.com/jb-alvarado/media-autobuild_suite/raw/master/build/media-suite_$($s).sh"
    }
}
if ($updateSuite) {
    if (-Not (Test-Path $instdir\update_suite.sh)) {
        Write-Host "-------------------------------------------------------------"
        Write-Host "Creating suite update file...`n"
        Write-Host "Run this file by dragging it to mintty before the next time you run"
        Write-Host "the suite and before reporting an issue.`n"
        Write-Host "It needs to be run separately and with the suite not running!"
        Write-Host "-------------------------------------------------------------"
    }
    $(
        Write-Output "#!/bin/bash`n"
        Write-Output "# Run this file by dragging it to mintty shortcut."
        Write-Output "# Be sure the suite is not running before using it!`n"
        Write-Output "update=yes"
        Start-Process -NoNewWindow -Wait -FilePath $instdir\$msys2\usr\bin\sed -ArgumentList"-n '/start suite update/,/end suite update/p' $build/media-suite_update.sh"
    ) | Out-File $instdir\update_suite.sh
}

# createFolders
function Write-BaseFolders {
    param (
        $baseFolder
    )
    if (-Not (Test-Path $instdir\$baseFolder\share)) {
        Write-Host "-------------------------------------------------------------"
        Write-Host "creating $baseFolder-bit install folders"
        Write-Host "-------------------------------------------------------------"
        mkdir $instdir\$baseFolder\bin
        mkdir $instdir\$baseFolder\bin-audio
        mkdir $instdir\$baseFolder\bin-global
        mkdir $instdir\$baseFolder\bin-video
        mkdir $instdir\$baseFolder\etc
        mkdir $instdir\$baseFolder\include
        mkdir $instdir\$baseFolder\lib\pkgconfig
        mkdir $instdir\$baseFolder\share
    }
}
if ($build64 -eq "yes") {
    Write-BaseFolders -baseFolder "local64"
}
if ($build32 -eq "yes") {
    Write-BaseFolders -baseFolder "local32"
}

$grep = "$instdir\$msys2\usr\bin\grep.exe"
$fstab = "$instdir\$msys2\etc\fstab"
# checkFstab
function Write-Fstab {
    Write-Host "-------------------------------------------------------------`n"
    Write-Host "- write fstab mount file`n"
    Write-Host "-------------------------------------------------------------"
    if ((Test-Path $fstab) -and $(Get-Content $fstab | Select-String -Pattern "binary")) {
        $cygdrive = "yes"
    }
    else {
        $cygdrive = "no"
    }
    if ($cygdrive -eq "no") {
        Write-Output "none / cygdrive binary,posix=0,noacl,user 0 0" | Out-File $fstab
    }
    $(
        Write-Output "`r`n$instdir\ /trunk"
        Write-Output "$instdir\build\ /build"
        Write-Output "$instdir\$msys2\mingw32\ /mingw32"
        Write-Output "$instdir\$msys2\mingw64\ /mingw64"
    ) | Out-File -Append $fstab
    if ($build32 -eq "yes") {
        Write-Output "$instdir\local32\ /local32" | Out-File -Append $fstab
    }
    if ($build64 -eq "yes") {
        Write-Output "$instdir\local64\ /local64" | Out-File -Append $fstab
    }
}


if (Test-Path $instdir\$msys2\etc\fstab) {
    $removefstab = "no"

    Invoke-Expression "$grep build32 $fstab"
    if ($LASTEXITCODE -eq 0) {
        $removefstab = "yes"
    }
    Invoke-Expression "$grep trunk $fstab"
    if ($LASTEXITCODE -eq 1) {
        $removefstab = "yes"
    }
    $searchRes = $((Get-Content $fstab | Select-String -Pattern "trunk" | Out-String -NoNewline).Split(' ') | Select-Object -Index 0)
    if ($searchRes -ne $instdir) {
        $removefstab = "no"
    }
    Invoke-Expression "$grep local32 $fstab"
    $removefstab = if (($LASTEXITCODE -eq 0) -and ($build32 -eq "no")) {
        "yes"
    }
    elseif (($LASTEXITCODE -eq 1) -and ($build32 -eq "yes")) {
        "yes"
    }
    Invoke-Expression "$grep local64 $fstab"
    $removefstab = if (($LASTEXITCODE -eq 0) -and ($build64 -eq "no")) {
        "yes"
    }
    elseif (($LASTEXITCODE -eq 1) -and ($build64 -eq "yes")) {
        "yes"
    }
    if ($removefstab -eq "yes") {
        Remove-Item $fstab
        Write-Fstab
    }
}
else {
    Write-Fstab
}

# update
if (Test-Path $build\update.log) {
    Remove-Item $build\update.log
}
Start-Process -Wait -NoNewWindow -FilePath $mintty -ArgumentList $($defaultMintty + "-t `"update autobuild suite`" --log $build\update.log /usr/bin/bash -l /build/media-suite_update.sh --build32=$build32 --build64=$build64")

if (Test-Path $build\update_core) {
    Write-Host "-------------------------------------------------------------"
    Write-Host "critical updates"
    Write-Host "-------------------------------------------------------------"
    Start-Process -Wait -NoNewWindow -FilePath $instdir\$msys2\usr\bin\sh.exe -ArgumentList "-l -c `"pacman -S --needed --noconfirm --ask=20 --asdeps bash pacman msys2-runtime"
    Remove-Item $build\update_core
}

if ($msys -eq "msys32") {
    Write-Host "-------------------------------------------------------------"
    Write-Host "second rebase $msys2 system"
    Write-Host "-------------------------------------------------------------"
    Start-Process -NoNewWindow -Wait -FilePath $instdir\$msys2\autorebase.bat
}
# Write config profiles
function Write-Profile {
    param (
        [validateset(64, 32)]$bit
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
        Write-Output "CARCH=`"`$`{MINGW_CHOST%%%%-*`}`"`n"
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
    ) | Out-File -NoNewline -Encoding utf8 $instdir\local$($bit)\etc\profile2.local
}

if ($build32 -eq "yes") {
    Write-Profile -bit 32
}
if ($build64 -eq "yes") {
    Write-Profile -bit 64
}

# loginProfile
if (Test-Path $instdir\$msys2\etc\profile.pacnew) {
    Move-Item -Force $instdir\$msys2\etc\profile.pacnew $instdir\$msys2\etc\profile
}
Start-Process -NoNewWindow -Wait -FilePath $grep -ArgumentList "-e 'profile2.local' $instdir\$msys2\etc\profile"
if ($LASTEXITCODE -eq 1) {
    $(
        Write-Output "if [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW64 ]]; then"
        Write-Output "   source /local64/etc/profile2.local"
        Write-Output "elif [[ -z `"`$MSYSTEM`" || `"`$MSYSTEM`" = MINGW32 ]]; then"
        Write-Output "   source /local32/etc/profile2.local"
        Write-Output "fi"
    ) | Out-File $instdir\$msys2\etc\profile.d\Zab-suite.sh
}

# compileLocals
Set-Location $instdir

if ($build64 -eq "yes") {
    $MSYSTEM = "MINGW64"
}
else {
    $MSYSTEM = "MINGW32"
}

$Host.UI.RawUI.WindowTitle = "MABSbat"
$ourPID = $PID

if (Test-Path $build\compile.log) {
    Remove-Item $build\compile.log
}

$compileArguments = "-t `"media-autobuild_suite`" --log $build\compile.log /bin/env SYSTEM=$MSYSTEM MSYS2_PATH_TYPE=inherit /usr/bin/bash --login /build/media-suite_compile.sh --cpuCount=$($jsonObjects.cpuCores) --build32=$($build32) --build64=$($build64) --deleteSource=$($deleteSource) --mp4box=$mp4box --vpx=$vpx2 --x264=$x2643 --x265=$x2652 --other265=$other265 --flac=$flac --fdkaac=$fdkaac --mediainfo=$mediainfo --sox=$sox --ffmpeg=$ffmpeg --ffmpegUpdate=$ffmpegUpdate --ffmpegChoice=$ffmpegChoice --mplayer=$mplayer --mpv=$mpv --license=$license2  --stripping=$strip --packing=$pack --rtmpdump=$rtmpdump --logging=$logging --bmx=$bmx --standalone=$standalone --aom=$aom --faac=$faac --ffmbc=$ffmbc --curl=$curl --cyanrip=$cyanrip2 --redshift=$redshift --rav1e=$rav1e --ripgrep=$ripgrep --dav1d=$dav1d --vvc=$vvc'"

Start-Process -NoNewWindow -Wait -FilePath $mintty -ArgumentList $($defaultMintty + $compileArguments)

$env:Path = $tempPath