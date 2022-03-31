# Multi option manual

Multi option (--multi/-m) allows easy multiplication of APRS packets read from APRS log file. This option could be useful for stress testing. 

## Example file
This short introduction explains how example APRS log file could be multiplied in various ways.

Example log content:
examples/ex1.aprs: 

```
# aprsc 2.1.5-g8af3cdc 7 May 2021 03:01:26 GMT GLIDERN5 88.99.111.134:10152
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
OGN123456>OGFLR,qAS,EPZR:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
FLR102030>OGFLR,qAS,EPZR:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06102030 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR102031>OGFLR,qAS,EPKA:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06102031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
OGN123456>OGFLR,qAS,EPZR:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
EPZR>OGNSDR,TCPIP*,qAC,Error in packet

```
It consists of packets from OGN stations, OGN trackers and FLARMS.
Additionally, APRSC comment messages are included together with corrupted packets.

## Multi file format

Multi option is controlled by JSON multi file. Multi file should be list of maps. Each map describes APRS output stream parameters.
Each stream takes data from input APRS file. 

### Basic stream copy
To understand the idea, minimal multi file is presented.

examples/multi1.json:

```
[
  {},
  {}
]
```
This multi file describes two unaltered streams.
ogn_sim executed with multi option should just copy original APRS file entries two times without any changes:

```
$ ./ogn_sim -f examples/ex1.aprs -m examples/multi1.json -l out.txt
$ cat out.txt
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
OGN123456>OGFLR,qAS,EPZR:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN123456>OGFLR,qAS,EPZR:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
FLR102030>OGFLR,qAS,EPZR:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06102030 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR102030>OGFLR,qAS,EPZR:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06102030 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR102031>OGFLR,qAS,EPKA:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06102031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
FLR102031>OGFLR,qAS,EPKA:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06102031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
OGN123456>OGFLR,qAS,EPZR:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN123456>OGFLR,qAS,EPZR:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
```

Such log is not very useful (maybe except testing packet duplicates scenarios).

### Stream copy with modified identifiers

Next step is to change identfiers of OGN entities in second stream:

examples/multi2.json:
```
[
  {},
  {"id": 1}
]
```
This multi file describes two streams: first one is original one, identifiers is second stream are modified.
```
$ ./ogn_sim -f examples/ex1.aprs -m examples/multi2.json -l out.txt
$ cat out.txt
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
OGN123456>OGFLR,qAS,EPZR:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
FLR102030>OGFLR,qAS,EPZR:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06102030 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR000021>OGFLR,qAS,EPZR1:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06000021 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR102031>OGFLR,qAS,EPKA:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06102031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
FLR000031>OGFLR,qAS,EPKA1:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06000031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
OGN123456>OGFLR,qAS,EPZR:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F123456 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
```
Basic APRS identifiers are created by appending "id" field.
OGN identifiers can't be created this way, as their length is constant. There are several ideas how this problem could be solved.
Ogn_sim dynamically counts OGN type identifiers and maintains OGN mapping table.
Additionally idxxxxxxxx string in comment section is updated too.

It is possible to create 16 streams.
Tag: "id" accepts number from 0 to 15.


### Stream copy with fully modified identifiers

Mapping presented in previous chapter is almost correct, but there is a chance that new OGN id created from internal counter will collide with real OGN id.
Chance is small, but it is possible to create 100% OGN id separation of streams using such multi file:

examples/multi3.json:
```
[
  {"id": 0},
  {"id": 1}
]
```

This multi file describes two streams. Identifiers in both streams are modified.

```
$ ./ogn_sim -f examples/ex1.aprs -m examples/multi3.json -l out.txt
$ cat out.txt
EPZR0>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR0>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
OGN000010>OGFLR,qAS,EPZR0:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000010 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
FLR000020>OGFLR,qAS,EPZR0:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06000020 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR000021>OGFLR,qAS,EPZR1:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06000021 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR000030>OGFLR,qAS,EPKA0:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06000030 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
FLR000031>OGFLR,qAS,EPKA1:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06000031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
OGN000010>OGFLR,qAS,EPZR0:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000010 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
```

### Stream copy with fully modified identifiers and moved objects

It is possible to geographically move objects of selected stream by selected offset.
Example multi file, examples/multi4.json:
```
[
  {"id": 0},
  {"id": 1, "lon_offset": 90}
]

```
Objects in second stream are moved 90 degress east.
```
$ ./ogn_sim -f examples/ex1.aprs -m examples/multi4.json -l out.txt
$ cat out.txt
EPZR0>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI10913.38E&/A=001447
EPZR0>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
OGN000010>OGFLR,qAS,EPZR0:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000010 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030130h5010.20N/10915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
FLR000020>OGFLR,qAS,EPZR0:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06000020 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR000021>OGFLR,qAS,EPZR1:/030130h5111.12N/11010.10En000/000/A=000587 !W38! id06000021 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR000030>OGFLR,qAS,EPKA0:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06000030 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
FLR000031>OGFLR,qAS,EPKA1:/030131h5234.13N/10900.15E'000/000/A=000781 !W32! id06000031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
OGN000010>OGFLR,qAS,EPZR0:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000010 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030131h5010.20N/10915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
```

It is also possible to update latitude of objects.
Example multi file, examples/multi5.json:
```
[
  {"id": 0},
  {"id": 1, "lon_offset": 90, "lat_offset": -10}
]
```
Objects in second stream are moved 10 degress south.

```
$ ./ogn_sim -f examples/ex1.aprs -m examples/multi5.json -l out.txt
$ cat out.txt
EPZR0>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h4946.47NI01913.38E&/A=001447
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:/030130h3946.47NI10913.38E&/A=001447
EPZR0>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
EPZR1>OGNSDR,TCPIP*,qAC,GLIDERN1:>030130h v0.2.7.x64 CPU:0.8 RAM:491.1/913.3MB NTP:0.5ms/+9.7ppm +68.0C
OGN000010>OGFLR,qAS,EPZR0:/030130h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000010 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030130h4010.20N/10915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
FLR000020>OGFLR,qAS,EPZR0:/030130h5111.12N/02010.10En000/000/A=000587 !W38! id06000020 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR000021>OGFLR,qAS,EPZR1:/030130h4111.12N/11010.10En000/000/A=000587 !W38! id06000021 -019fpm +0.0rot 11.2dB -9.0kHz gps1x2
FLR000030>OGFLR,qAS,EPKA0:/030131h5234.13N/01900.15E'000/000/A=000781 !W32! id06000030 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
FLR000031>OGFLR,qAS,EPKA1:/030131h4234.13N/10900.15E'000/000/A=000781 !W32! id06000031 +059fpm +0.0rot 10.8dB -7.5kHz gps4x6
OGN000010>OGFLR,qAS,EPZR0:/030131h5010.20N/01915.30Eg000/002/A=000335 !W57! id1F000010 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
OGN000011>OGFLR,qAS,EPZR1:/030131h4010.20N/10915.30Eg000/002/A=000335 !W57! id1F000011 +000fpm +0.0rot 52.5dB -4.0kHz gps3x5
```

Please note that adding offset to latitude will introduce distortion in object paths.
Using "lon_offset" should be preffered - adding any offset to object longitude preserves all path parameters.
