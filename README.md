# OGN Simulator

The main purpose of this tool is to simulate an APRS server that generates Open Glider Network packets.
Generated traffic could composed of:
- APRS packets with simulated object data,
- APRS packets replayed from OGN log files.

## Purpose
Main purpose of the tool is GAT Core server performance testing, but it could be used for testing selected OGN components.

## Compiling
Erlang (>=22) and Elixir (>=1.11) must be installed.
Following commands should be executed in repository folder:

```
$ mix deps.get
$ mix escript.build
```
Compiled binary name is ogn_sim.

## Options

CLI options:

```
$ ./ogn_sim -h
ogn_sim args:
--help,  -h: print help,
--port,  -p: APRS server listen TCP port, default: 10152,
--name,  -n: APRS server name, default: OGNSIM,
--objs,  -o: number of simulated OGN objects, default: 0,
--file,  -f: simulate traffic from selected APRS log file,
--multi, -m: multipy traffic from --file using provided JSON schema,
--log,   -l: log output to provided file,
--rate,  -r: show packet rates.
```

### APRS server
Parameters of simulated APRS are controlled by --port and --name options.
Simulated server functionality is limited to:
* full-feed (10152) stream, no filters are accepted,
* server accepts TCP connections only, there is no uplink possible,
* multiple TCP connections to full-feed port are allowed.

Server won't send any packets when executed without options, but it is possible to connect to it:
```
$ ./ogn_sim 
OGN APRS traffic simulator.
APRS server OGNSIM started, listening on port: 10152
Enter h - for help
Enter command: APRS connection "CORE-1": started.
Enter command: h
ogn_sim commands:
h: help,
q: quit program,
c: APRS clients list,
r: toggle packet rate display.

Enter command: c
APRS client(s):
id: CORE-1, IP: 192.168.1.11:37224
Enter command: q
$
```

### Simulated objects
Using --objs options it is possible to start selected number of simulated objects

```
$ ./ogn_sim -o 1000
OGN APRS traffic simulator.
APRS server OGNSIM started, listening on port: 10152
Starting 1000 object(s)
Enter h - for help
```
Those objects are simulated OGN Trackers hanging in the air over Kraków, but they are valid since their callsigns differ and reported time is progressing.

### APRS log reply
It is also possible to reply recorded APRS traffic using --file option:

```
$ ./ogn_sim -f logs/test_log.aprs.gz 
OGN APRS traffic simulator.
APRS server OGNSIM started, listening on port: 10152
Starting logs/test_log.aprs.gz file
Enter h - for help
```

Gzip compressed files are accepted.

### APRS log multiplication
Log multiplication allows easy creation of artificial APRS traffic.

```
$ ./ogn_sim -f logs/test_log.aprs.gz -m examples/multi4.json
OGN APRS traffic simulator.
APRS server OGNSIM started, listening on port: 10152
Starting logs/test_log.aprs.gz file
Enter h - for help
```

Multi option is documented multi.md file.

