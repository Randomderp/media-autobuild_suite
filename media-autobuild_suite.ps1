# Set window title
$Host.UI.RawUI.WindowTitle = "media-autobuild_suite"

# Eq to instdir in the Batch file
$instdir = Split-Path -Path $MyInvocation.MyCommand.Path

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
    Write-Host "$(Split-Path -Path $MyInvocation.MyCommand.Path)`n"
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

# Set bitness, not build bit. Eq to _bitness
$bitness = switch ([System.IntPtr]::Size) {
    4 {32}
    Default {64}
}

# Set Build path
$build = "$($instdir)\build"
if (-Not (Test-Path $build -PathType Container)) {
    mkdir -Name "build" -Path $instdir 2>&1 | Out-Null
}

# Set package variables
# change ini options to hashtable+json later
$msyspackages = "asciidoc", "autoconf", "automake-wrapper", "autogen", "bison", "diffstat", "dos2unix", "help2man", "intltool", "libtool", "patch", "python", "xmlto", "make", "zip", "unzip", "git", "subversion", "wget", "p7zip", "mercurial", "man-db", "gperf", "winpty", "texinfo", "gyp-git", "doxygen", "autoconf-archive", "itstool", "ruby", "mintty"
$mingwpackages = "cmake", "dlfcn", "libpng", "gcc", "nasm", "pcre", "tools-git", "yasm", "ninja", "pkg-config", "meson"
$ffmpeg_options_builtin = "--disable-autodetect", "amf", "bzlib", "cuda", "cuvid", "d3d11va", "dxva2", "iconv", "lzma", "nvenc", "schannel", "zlib", "sdl2", "--disable-debug", "ffnvcodec", "nvdec"
$ffmpeg_options_basic = "gmp", "libmp3lame", "libopus", "libvorbis", "libvpx", "libx264", "libx265", "libdav1d"
$ffmpeg_options_zeranoe = "fontconfig", "gnutls", "libass", "libbluray", "libfreetype", "libmfx", "libmysofa", "libopencore-amrnb", "libopencore-amrwb", "libopenjpeg", "libsnappy", "libsoxr", "libspeex", "libtheora", "libtwolame", "libvidstab", "libvo-amrwbenc", "libwavpack", "libwebp", "libxml2", "libzimg", "libshine", "gpl", "openssl", "libtls", "avisynth", "mbedtls", "libxvid", "libaom", "version3"
$ffmpeg_options_full = "chromaprint", "cuda-sdk", "decklink", "frei0r", "libbs2b", "libcaca", "libcdio", "libfdk-aac", "libflite", "libfribidi", "libgme", "libgsm", "libilbc", "libkvazaar", "libmodplug", "libnpp", "libopenh264", "libopenmpt", "librtmp", "librubberband", "libssh", "libtesseract", "libxavs", "libzmq", "libzvbi", "opencl", "opengl", "libvmaf", "libcodec2", "libsrt", "ladspa", "#vapoursynth", "#liblensfun", "libndi_newtek"
$mpv_options_builtin = "#cplayer", "#manpage-build", "#lua", "#javascript", "#libass", "#libbluray", "#uchardet", "#rubberband", "#lcms2", "#libarchive", "#libavdevice", "#shaderc", "#crossc", "#d3d11", "#jpeg"
$mpv_options_basic = "--disable-debug-build", "--lua=luajit"
$mpv_options_full = "dvdread", "dvdnav", "cdda", "egl-angle", "vapoursynth", "html-build", "pdf-build", "libmpv-shared"
$iniOptions = @("msys2Arch", "arch", "license2", "standalone", "vpx2", "aom", "rav1e", "dav1d", "x2643", "x2652", "other265", "flac", "fdkaac", "faac", "mediainfo", "soxB", "ffmpegB2", "ffmpegUpdate", "ffmpegChoice", "mp4box", "rtmpdump", "mplayer2", "mpv", "bmx", "curl", "ffmbc", "cyanrip2", "redshift", "ripgrep", "cores", "deleteSource", "strip", "pack", "logging", "updateSuite", "forceQuitBatch")

#$previousOptions = $false # redundant, probably
#$msys2ArchINI = 0 # also redundant, probably
$ini = "$build\media-autobuild_suite.ini"

# make blank ini so that select-string doesn't throw a bunch of errors, I could just suppress them, but at the same time, it makes the second part easier.
# checkINI
if (Test-Path -Path $ini) {
    foreach ($a in $iniOptions) {
        if ($null -ne (Select-String -Pattern $a -CaseSensitive $ini | Select-Object Line | Out-String -NoNewline).Split('=')[1]) {
            Set-Variable -Name "$($a)INI" -Value $((Select-String -Pattern $a -CaseSensitive $ini | Select-Object Line | Out-String -NoNewline).Split('=')[1])
            switch ($a) {
                license2 {
                    Set-Variable -Name "ffmpeglicense2" -Value $((Select-String -Pattern $a -CaseSensitive $ini | Select-Object Line | Out-String -NoNewline).Split('=')[1])
                }
                cores {
                    Set-Variable -Name "cores" -Value $((Select-String -Pattern $a -CaseSensitive $ini | Select-Object Line | Out-String -NoNewline).Split('=')[1])

                }
                deleteSource {
                    Set-Variable -Name "deleteS" -Value $((Select-String -Pattern $a -CaseSensitive $ini | Select-Object Line | Out-String -NoNewline).Split('=')[1])
                }
                strip {
                    Set-Variable -Name "stripF" -Value $((Select-String -Pattern $a -CaseSensitive $ini | Select-Object Line | Out-String -NoNewline).Split('=')[1])
                }
                Default {
                    Set-Variable -Name "build$($a)" -Value $((Select-String -Pattern $a -CaseSensitive $ini | Select-Object Line | Out-String -NoNewline).Split('=')[1])
                }
            }
        }
        else {
            Set-Variable -Name "$($a)INI" -Value 0
            switch ($a) {
                "license2" {
                    Set-Variable -Name "ffmpeglicense2" -Value 0
                }
                "cores" {
                    Set-Variable -Name "cpuCores" -Value 0
                }
                "deleteSource" {
                    Set-Variable -Name "deleteS" -Value 0
                }
                "strip" {
                    Set-Variable -Name "stripF" -Value 0
                }
                Default {
                    Set-Variable -Name "build$($a)" -Value 0
                }
            }
            Set-Variable -Name "write$($a)" -Value $true
        }
    }
}
else {
    foreach ($a in $iniOptions) {
        $b = "$($a)INI"
        Set-Variable -Name "$($a)INI" -Value 0
        Set-Variable -Name "write$($a)" -Value $true
        switch ($a) {
            "license2" {Set-Variable -Name "ffmpeglicense2" -Value 0}
            Default {Set-Variable -Name "build$($a)" -Value 0}
        }
    }
    $msys2Arch = switch ($bitness) {
        64 {2}
        Default {1}
    }
    Write-Output "[compiler list]" | Out-File $ini
    Write-Output "msys2Arch=$msys2Arch" | Out-File -Append $ini
    $msys2ArchINI = $msys2Arch
}

# sytemVars
$msys2Arch = $msys2ArchINI
$msys2 = switch ($msys2Arch) {
    1 {"msys32"}
    Default {"msys64"}
}

# selectSystem
while (1..3 -notcontains $buildarch) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-Host "Select the build target system:"
    Write-Host "1 = both [32 bit and 64 bit]"
    Write-Host "2 = 32 bit build system"
    Write-Host "3 = 64 bit build system`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $buildarch = Read-Host -Prompt "Build System: "
}
if ($writearch) {
    Write-Output "arch=$buildarch" | Out-File -Append $ini
}
switch ($buildarch) {
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

# ffmpeglicense
while (1..5 -notcontains $ffmpeglicense2) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-Host "Build FFmpeg with which license?"
    Write-Host "1 = Non-free [unredistributable, but can include anything]"
    Write-Host "2 = GPLv3 [disables OpenSSL and FDK-AAC]"
    Write-Host "3 = GPLv2.1"
    Write-Host "  [Same disables as GPLv3 with addition of gmp, opencore codecs]"
    Write-Host "4 = LGPLv3"
    Write-Host "  [Disables x264, x265, XviD, GPL filters, etc."
    Write-Host "   but reenables OpenSSL/FDK-AAC]"
    Write-Host "5 = LGPLv2.1 [same disables as LGPLv3 + GPLv2.1]`n"
    Write-Host "If building for yourself, it's OK to choose non-free."
    Write-Host "If building to redistribute online, choose GPL or LGPL."
    Write-Host "If building to include in a GPLv2.1 binary, choose LGPLv2.1 or GPLv2.1."
    Write-Host "If you want to use FFmpeg together with closed source software, choose LGPL"
    Write-Host "and follow instructions in https://www.ffmpeg.org/legal.html`n"
    Write-Host "OpenSSL and FDK-AAC have licenses incompatible with GPL but compatible"
    Write-Host "with LGPL, so they won't be disabled automatically if you choose LGPL.`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $ffmpeglicense2 = Read-Host -Prompt "FFmpeg license: "
}
if ($writelicense2) {
    Write-Output "license2=$ffmpeglicense2" | Out-File -Append $ini
}
$license2 = switch ($ffmpeglicense2) {
    1 {"nonfree"}
    2 {"gplv3"}
    3 {"gpl"}
    4 {"lgplv3"}
    5 {"lgpl"}
}

# standalone
while (1..2 -notcontains $buildstandalone) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-host "Build standalone binaries for libraries included in FFmpeg?"
    Write-host "eg. Compile opusenc.exe if --enable-libopus"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildstandalone = Read-Host -Prompt "Build standalone binaries: "
}
$standalone = switch ($buildstandalone) {
    1 {"y"}
    2 {"n"}
}
$buildstandalone
Write-Host $standalone
if ($writestandalone) {
    Write-Output "standalone=$buildstandalone" | Out-File -Append $ini
}

# I could condense all of the y or n using a switch array along with for and set-variable.
# Leaving that for the optimization part.
# vpx
while (1..2 -notcontains $buildvpx2) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build vpx [VP8/VP9/VP10 encoder]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "Binaries being built depends on 'standalone=y'`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildvpx2 = Read-Host -Prompt "Build vpx: "
}
if ($writevpx2) {
    Write-Output "vpx2=$buildvpx2" | Out-File -Append $ini
}
$vpx2 = switch ($buildvpx2) {
    1 {"y"}
    Default {"n"}
}

# aom
while (1..2 -notcontains $buildaom) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build aom [Alliance for Open Media codec]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "Binaries being built depends on 'standalone=y'`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildaom = Read-Host -Prompt "Build aom: "
}
if ($writeaom) {
    Write-Output "aom=$buildaom" | Out-File -Append $ini
}
$aom = switch ($buildaom) {
    1 {"y"}
    Default {"n"}
}

# rav1e
while (1..2 -notcontains $buildrav1e) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-host "Build rav1e [Alternative, faster AV1 standalone encoder]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildrav1e = Read-Host -Prompt "Build rav1e: "
}
if ($writerav1e) {
    Write-Output "rav1e=$buildrav1e" | Out-File -Append $ini
}
$rav1e = switch ($buildrav1e) {
    1 {"y"}
    Default {"n"}
}

# dav1e
while (1..2 -notcontains $builddav1d) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build dav1d [Alternative, faster AV1 decoder]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $builddav1d = Read-Host -Prompt "Build aom: "
}
if ($writedav1d) {
    Write-Output "dav1d=$builddav1d" | Out-File -Append $ini
}
$dav1d = switch ($builddav1d) {
    1 {"y"}
    Default {"n"}
}

# I might be able to put the question part into the default option for the switch in order to check if -eq 0 then ask. Might help with resuming from a premature end.
# x264
while (1..7 -notcontains $buildx2643) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-host "Build x264 [H.264 encoder]?"
    Write-host "1 = Lib/binary with 8 and 10-bit"
    Write-host "2 = No"
    Write-host "3 = Lib/binary with only 10-bit"
    Write-host "4 = Lib/binary with 8 and 10-bit, and libavformat and ffms2"
    Write-host "5 = Shared lib/binary with 8 and 10-bit"
    Write-host "6 = Same as 4 with video codecs only ^(can reduce size by ~3MB^)"
    Write-host "7 = Lib/binary with only 8-bit`n"
    Write-host "Binaries being built depends on 'standalone=y' and are always static.`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $buildx2643 = Read-Host -Prompt "Build x264: "
}
if ($writex2643) {
    Write-Output "x2643=$buildx2643" | Out-File -Append $ini
}
$x2643 = switch ($buildx2643) {
    1 {"yes"}
    2 {"no"}
    3 {"high"}
    4 {"full"}
    5 {"shared"}
    6 {"fullv"}
    7 {"o8"}
}


#x265
while (1..7 -notcontains $buildx2652) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-host "Build x265 [H.265 encoder]?"
    Write-host "1 = Lib/binary with Main, Main10 and Main12"
    Write-host "2 = No"
    Write-host "3 = Lib/binary with Main10 only"
    Write-host "4 = Lib/binary with Main only"
    Write-host "5 = Lib/binary with Main, shared libs with Main10 and Main12"
    Write-host "6 = Same as 1 with XP support and non-XP compatible x265-numa.exe"
    Write-host "7 = Lib/binary with Main12 only`n"
    Write-host "Binaries being built depends on 'standalone=y'`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $buildx2652 = Read-Host -Prompt "Build x265: "
}
if ($writex2652) {
    Write-Output "x2652=$buildx2652" | Out-File -Append $ini
}
$x2652 = switch ($buildx2652) {
    1 {"y"}
    2 {"n"}
    3 {"o10"}
    4 {"o8"}
    5 {"s"}
    6 {"d"}
    7 {"o12"}
}

#other265
while (1..2 -notcontains $buildother265) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build standalone Kvazaar?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildother265 = Read-Host -Prompt "Build kvazaar: "
}
if ($writeother265) {
    Write-Output "other265=$buildother265" | Out-File -Append $ini
}
$other265 = switch ($buildother265) {
    1 {"y"}
    Default {"n"}
}


# flac
while (1..2 -notcontains $buildflac) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build FLAC [Free Lossless Audio Codec]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildflac = Read-Host -Prompt "Build flac: "
}
if ($writeflac) {
    Write-Output "flac=$buildflac" | Out-File -Append $ini
}
$flac = switch ($buildflac) {
    1 {"y"}
    Default {"n"}
}


#fdkaac
while (1..2 -notcontains $buildfdkaac) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build FDK-AAC library and binary [AAC-LC/HE/HEv2 codec]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "Note: FFmpeg's aac encoder is no longer experimental and considered equal or"
    Write-host "better in quality from 96kbps and above. It still doesn't support AAC-HE/HEv2"
    Write-host "so if you need that or want better quality at lower bitrates than 96kbps,"
    Write-host "use FDK-AAC.`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildfdkaac = Read-Host -Prompt "Build fdkaac: "
}
if ($writefdkaac) {
    Write-Output "fdkaac=$buildfdkaac" | Out-File -Append $ini
}
$fdkaac = switch ($buildfdkaac) {
    1 {"y"}
    Default {"n"}
}


# faac
while (1..2 -notcontains $buildfaac) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build FAAC library and binary [old, low-quality and nonfree AAC-LC codec]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildfaac = Read-Host -Prompt "Build faac: "
}
if ($writefaac) {
    Write-Output "faac=$buildfaac" | Out-File -Append $ini
}
$faac = switch ($buildfaac) {
    1 {"y"}
    Default {"n"}
}


# mediainfo
while (1..2 -notcontains $buildmediainfo) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build mediainfo binaries [Multimedia file information tool]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildmediainfo = Read-Host -Prompt "Build mediainfo: "
}
if ($writemediainfo) {
    Write-Output "mediainfo=$buildmediainfo" | Out-File -Append $ini
}
$mediainfo = switch ($buildmediainfo) {
    1 {"y"}
    Default {"n"}
}


# sox
while (1..2 -notcontains $buildsoxB) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build sox binaries [Sound processing tool]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildsoxB = Read-Host -Prompt "Build sox: "
}
if ($writesoxB) {
    Write-Output "soxB=$buildsoxB" | Out-File -Append $ini
}
$sox = switch ($buildsoxB) {
    1 {"y"}
    Default {"n"}
}

# ffmpeg
while (1..5 -notcontains $buildffmpegB2) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-host "Build FFmpeg binaries and libraries:"
    Write-host "1 = Yes [static] [recommended]"
    Write-host "2 = No"
    Write-host "3 = Shared"
    Write-host "4 = Both static and shared [shared goes to an isolated directory]"
    Write-host "5 = Shared-only with some shared libs ^(libass, freetype and fribidi^)`n"
    Write-host "Note: Option 5 differs from 3 in that libass, freetype and fribidi are"
    Write-host "compiled shared so they take less space. This one isn't tested a lot and"
    Write-host "will fail with fontconfig enabled.`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $buildffmpegB2 = Read-Host -Prompt "Build FFmpeg: "
}
if ($writeffmpegB2) {
    Write-Output "ffmpegB2=$buildffmpegB2" | Out-File -Append $ini
}
$ffmpeg = switch ($buildffmpegB2) {
    1 {"nonfree"}
    2 {"gplv3"}
    3 {"gpl"}
    4 {"lgplv3"}
    5 {"lgpl"}
}


# ffmpegUp
while (1..3 -notcontains $buildffmpegUpdate) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-host "Always build FFmpeg when libraries have been updated?"
    Write-host "1 = Yes"
    Write-host "2 = No"
    Write-host "3 = Only build FFmpeg/mpv and missing dependencies`n"
    Write-host "FFmpeg is updated a lot so you only need to select this if you"
    Write-host "absolutely need updated external libraries in FFmpeg.`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $buildffmpegUpdate = Read-Host -Prompt "Build ffmpeg if lib is new: "
}
if ($writeffmpegUpdate) {
    Write-Output "ffmpegUpdate=$buildffmpegUpdate" | Out-File -Append $ini
}
$ffmpegUpdate = switch ($buildffmpegUpdate) {
    1 {"y"}
    2 {"n"}
    3 {"onlyFFmpeg"}
}


#ffmpegChoice
while (1..4 -notcontains $buildffmpegChoice) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-host "Choose ffmpeg and mpv optional libraries?"
    Write-host "1 = Yes"
    Write-host "2 = No ^(Light build^)"
    Write-host "3 = No ^(Mimic Zeranoe^)"
    Write-host "4 = No ^(All available external libs^)`n"
    Write-host "Avoid the last two unless you're really want useless libraries you'll never use."
    Write-host "Just because you can include a shitty codec no one uses doesn't mean you should.`n"
    Write-host "If you select yes, we will create files with the default options"
    Write-host "we use with FFmpeg and mpv. You can remove any that you don't need or prefix"
    Write-host "them with #`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $buildffmpegChoice = Read-Host -Prompt "Choose ffmpeg and mpv optional libs: "
}
if ($writeffmpegChoice) {
    Write-Output "ffmpegChoice=$buildffmpegChoice" | Out-File -Append $ini
}

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
switch ($buildffmpegChoice) {
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

#mp4boxStatic
while (1..2 -notcontains $buildmp4box) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build static mp4box [mp4 muxer/toolbox] binary?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildmp4box = Read-Host -Prompt "Build mp4box: "
}
if ($writemp4box) {
    Write-Output "mp4box=$buildmp4box" | Out-File -Append $ini
}
$mp4box = switch ($buildmp4box) {
    1 {"y"}
    Default {"n"}
}

# rtmpdump
while (1..2 -notcontains $buildrtmpdump) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build static rtmpdump binaries [rtmp tools]?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildrtmpdump = Read-Host -Prompt "Build rtmpdump: "
}
if ($writertmpdump) {
    Write-Output "rtmpdump=$buildrtmpdump" | Out-File -Append $ini
}
$rtmpdump = switch ($buildrtmpdump) {
    1 {"y"}
    Default {"n"}
}

# mplayer
while (1..2 -notcontains $buildmplayer2) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "######### UNSUPPORTED, IF IT BREAKS, IT BREAKS ################################`n"
    Write-host "Build static mplayer/mencoder binary?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "Don't bother opening issues about this if it breaks, I don't fucking care"
    Write-host "about ancient unmaintained shit code. One more issue open about this that"
    Write-host "isn't the suite's fault and mplayer goes fucking out.`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildmplayer2 = Read-Host -Prompt "Build mplayer: "
}
if ($writemplayer2) {
    Write-Output "mplayer2=$buildmplayer2" | Out-File -Append $ini
}
$mplayer = switch ($buildmplayer2) {
    1 {"y"}
    Default {"n"}
}

#mpv
while (1..3 -notcontains $buildmpv) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-host "Build mpv?"
    Write-host "1 = Yes"
    Write-host "2 = No"
    Write-host "3 = compile with Vapoursynth, if installed [see Warning]`n"
    Write-host "Note: when built with shared-only FFmpeg, mpv is also shared."
    Write-host "Note: Requires at least Windows Vista."
    Write-host "Warning: the third option isn't completely static. There's no way to include"
    Write-host "a library dependant on Python statically. All users of the compiled binary"
    Write-host "will need VapourSynth installed using the official package to even open mpv!`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildmpv = Read-Host -Prompt "Build mpv: "
}
if ($writempv) {
    Write-Output "mpv=$buildmpv" | Out-File -Append $ini
}
$mpv = switch ($buildmpv) {
    1 {"y"}
    2 {"n"}
    3 {"z"}
}

#bmx
while (1..2 -notcontains $buildbmx) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build static bmx tools?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildbmx = Read-Host -Prompt "Build bmx: "
}
if ($writebmx) {
    Write-Output "bmx=$buildbmx" | Out-File -Append $ini
}
$bmx = switch ($buildbmx) {
    1 {"y"}
    Default {"n"}
}

# curl
while (1..7 -notcontains $buildcurl) {
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------`n"
    Write-host "Build static curl?"
    Write-host "1 = Yes ^(same backend as FFmpeg's^)"
    Write-host "2 = No"
    Write-host "3 = SChannel backend"
    Write-host "4 = GnuTLS backend"
    Write-host "5 = OpenSSL backend"
    Write-host "6 = LibreSSL backend"
    Write-host "7 = mbedTLS backend`n"
    Write-host "A curl-ca-bundle.crt will be created to be used as trusted certificate store"
    Write-host "for all backends except SChannel.`n"
    Write-Host "-------------------------------------------------------------------------------"
    Write-Host "-------------------------------------------------------------------------------"
    $buildcurl = Read-Host -Prompt "Build x264: "
}
if ($writecurl) {
    Write-Output "curl=$buildcurl" | Out-File -Append $ini
}
$curl = switch ($buildcurl) {
    1 {"y"}
    2 {"n"}
    3 {"schannel"}
    4 {"gnutls"}
    5 {"openssl"}
    6 {"libressl"}
    7 {"mbedtls"}
}

# ffmbc
while (1..2 -notcontains $buildffmbc) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-host "Build FFMedia Broadcast binary?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "Note: this is a fork of FFmpeg 0.10. As such, it's very likely to fail"
    Write-host "to build, work, might burn your computer, kill your children, like mplayer."
    Write-host "Only enable it if you absolutely need it. If it breaks, complain first to"
    Write-host "the author in #ffmbc in Freenode IRC.`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildffmbc = Read-Host -Prompt "Build ffmbc: "
}
if ($writeffmbc) {
    Write-Output "ffmbc=$buildffmbc" | Out-File -Append $ini
}
$ffmbc = switch ($buildffmbc) {
    1 {"y"}
    Default {"n"}
}

# cyanrip
while (1..2 -notcontains $buildcyanrip2) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build cyanrip (CLI CD ripper)?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildcyanrip2 = Read-Host -Prompt "Build cyanrip: "
}
if ($writecyanrip2) {
    Write-Output "cyanrip2=$buildcyanrip2" | Out-File -Append $ini
}
$cyanrip2 = switch ($buildcyanrip2) {
    1 {"yes"}
    Default {"no"}
}

# redshift
while (1..2 -notcontains $buildredshift) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build redshift (f.lux FOSS clone)?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildredshift = Read-Host -Prompt "Build redshift: "
}
if ($writeredshift) {
    Write-Output "redshift=$buildredshift" | Out-File -Append $ini
}
$redshift = switch ($buildredshift) {
    1 {"y"}
    Default {"n"}
}

while (1..2 -notcontains $buildripgrep) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Build ripgrep (faster grep in Rust)?"
    Write-host "1 = Yes"
    Write-host "2 = No`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $buildripgrep = Read-Host -Prompt "Build ripgrep: "
}
if ($writeripgrep) {
    Write-Output "ripgrep=$buildripgrep" | Out-File -Append $ini
}
$ripgrep = switch ($buildripgrep) {
    1 {"y"}
    Default {"n"}
}

# numCores
# Still don't understand why the for /l loop on 1,1,%cpuCores%
$coresrecommend = switch ((Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors) {
    1 {1}
    Default {
        (Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors / 2
    }
}
while ($cores -eq 0) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Number of CPU Cores/Threads for compiling:"
    Write-Host "[it is non-recommended to use all cores/threads!]`n"
    Write-Host "Recommended: $coresrecommend"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $cores = Read-Host -Prompt "Core/Thread Count: "
}
if ($writecores) {
    Write-Output "cores=$cores" | Out-File -Append $ini
}

#delete
while (1..2 -notcontains $deleteS) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Delete versioned source folders after compile is done?"
    Write-host "1 = Yes [recommended]"
    Write-host "2 = No`n"
    Write-Host "This will save a bit of space for libraries not compiled from git/hg/svn.`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $deleteS = Read-Host -Prompt "Delete source: "
}
if ($writedeleteSource) {
    Write-Host "deleteSource=$deleteS" | Out-File -Append $ini
}
$deleteSource = switch ($deleteS) {
    1 {"n"}
    Default {"y"}
}

# stripEXE
while (1..2 -notcontains $stripF) {
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------`n"
    Write-Host "Strip compiled files binaries?"
    Write-host "1 = Yes [recommended]"
    Write-host "2 = No`n"
    Write-Host "Makes binaries smaller at only a small time cost after compiling.`n"
    Write-host "-------------------------------------------------------------------------------"
    Write-host "-------------------------------------------------------------------------------"
    $stripF = Read-Host -Prompt "Strip files: "
}
if ($writestrip) {
    Write-Host "strip=$stripF" | Out-File -Append $ini
}
$stripFile = switch ($stripF) {
    2 {"n"}
    Default {"y"}
}

# packEXE



#(Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors / 2
#Invoke-WebRequest https://i.fsbn.eu/pub/wget-pack.exe -o "wget-pack.exe"
#(get-filehash -algorithm sha256 wget-pack.exe).hash