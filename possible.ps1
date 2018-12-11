# possible things I might add
# ignore this for now, might actually do it later
param(
    [ValidateSet("64", "32", "both")][string]$bit,
    [ValidateSet("Non-free", "GPLv3", "GPLv2.1", "LGPLv3", "LGPLv2.1")]$license,
    [switch]$standalone,
    [switch]$vpx,
    [switch]$aom,
    [switch]$rav1e,
    [switch]$dav1d,
    [ValidateSet("no", "8and10", "shared8and10", "8only", "10only", "8and10ffm2libav", "codeconly")]$x264,
    [ValidateSet("no", "main", "main10", "main12", "8and10and12", "shared", "xp")]$x265,
    [switch]$kvazaar,
    [switch]$flac,
    [switch]$fdkaac,
    [switch]$faac,
    [switch]$mediainfo,
    [switch]$sox,
    [ValidateSet("no", "static", "shared", "both", "sharedsharedlibs")]$ffmpeg,
    [ValidateSet("no", "yes", "onlyffmpegmpv")]$alwaysbuildffmpeg,
    [ValidateSet("yes", "light", "zeranoe", "all")]$optionallib,
    [switch]$mp4box,
    [switch]$rtmpdump,
    [switch]$mplayer,
    [ValidateSet("no", "yes", "vapoursynth")]$mpv,
    [switch]$bmx,
    [ValidateSet("no", "ffmpeg", "schannel", "gnutls", "openssl", "libressl", "mbedtls")]$curl,
    [switch]$ffbroadcast,
    [switch]$cyanrip,
    [switch]$redshift,
    [switch]$ripgrep,
    [int]$cores = (Get-CimInstance -ClassName 'Win32_ComputerSystem').NumberOfLogicalProcessors / 2,
    [switch]$versioned,
    [switch]$strip,
    [switch]$pack,
    [switch]$log,
    [switch]$updatescript
)